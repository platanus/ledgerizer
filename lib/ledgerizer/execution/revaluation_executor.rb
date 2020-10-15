module Ledgerizer
  class RevaluationExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    def initialize(
      config:, tenant:,
      revaluation_name:, revaluation_time:, conversion_amount:,
      account_name:, accountable:, currency:
    )
      @config = config
      @tenant = tenant
      tenant_definition = get_tenant_definition!
      @revaluation_definition = get_revaluation_definition!(tenant_definition, revaluation_name)
      @revaluation_time = get_revaluation_time!(revaluation_time)
      @conversion_amount = get_conversion_amount!(conversion_amount)
      @currency = get_currency!(currency)
      @account_definition = get_account_definition!(tenant_definition, account_name)
      @accountable = get_accountable!(accountable)
    end

    def execute
      return false if revaluation_diff.zero?

      add_debit_movement
      add_credit_movement
      entry_executor.execute
    end

    private

    REVALUATION_ENTRY_MOVEMENTS_CONFIG = {
      asset_positive: {
        debit_account_name: Proc.new { account_definition.name },
        debit_accountable: Proc.new { accountable },
        credit_account_name: Proc.new { revaluation_definition.income_revaluation_account },
        credit_accountable: Proc.new { nil }
      },
      asset_negative: {
        debit_account_name: Proc.new { revaluation_definition.expense_revaluation_account },
        debit_accountable: Proc.new { nil },
        credit_account_name: Proc.new { account_definition.name },
        credit_accountable: Proc.new { accountable }
      },
      liability_positive: {
        debit_account_name: Proc.new { account_definition.name },
        debit_accountable: Proc.new { accountable },
        credit_account_name: Proc.new { revaluation_definition.expense_revaluation_account },
        credit_accountable: Proc.new { nil }
      },
      liability_negative: {
        debit_account_name: Proc.new { revaluation_definition.income_revaluation_account },
        debit_accountable: Proc.new { nil },
        credit_account_name: Proc.new { account_definition.name },
        credit_accountable: Proc.new { accountable }
      }
    }

    attr_reader :config, :account_definition, :revaluation_definition
    attr_reader :tenant, :accountable, :revaluation_time, :conversion_amount, :currency

    def add_debit_movement
      add_movement(:debit)
    end

    def add_credit_movement
      add_movement(:credit)
    end

    def add_movement(movement_type)
      entry_executor.add_new_movement(
        movement_type: movement_type.to_sym,
        account_name: get_movement_config("#{movement_type}_account_name"),
        accountable: get_movement_config("#{movement_type}_accountable"),
        mirror_currency: account_instance.currency,
        amount: revaluation_diff_abs
      )
    end

    def get_movement_config(key)
      instance_eval(&REVALUATION_ENTRY_MOVEMENTS_CONFIG[movement_config_key.to_sym][key.to_sym])
    end

    def movement_config_key
      "#{account_type}_#{revaluation_direction}".to_sym
    end

    def entry_executor
      @entry_executor ||= Ledgerizer::EntryExecutor.new(
        config: config,
        tenant: tenant,
        document: revaluation_instance,
        entry_code: revaluation_entry_code,
        entry_time: revaluation_time,
        conversion_amount: nil
      )
    end

    def revaluation_entry_code
      @revaluation_entry_code ||= begin
        entry_method = "#{revaluation_direction}_#{account_type}_entry_code"
        revaluation_definition.send(entry_method)
      end
    end

    def account_type
      @account_type ||= begin
        type = nil

        if asset_revaluation?
          type = :asset
        elsif liability_revaluation?
          type = :liability
        else
          raise_error("#{account_definition.name} must be asset or liability")
        end

        type
      end
    end

    def revaluation_direction
      @revaluation_direction ||= begin
        if asset_revaluation?
          revaluation_diff.positive? ? :positive : :negative
        else
          revaluation_diff.positive? ? :negative : :positive
        end
      end
    end

    def revaluation_diff_abs
      revaluation_diff.abs
    end

    def revaluation_diff
      @revaluation_diff ||= account_balance_in_tenant_currency - mirror_account_balance
    end

    def mirror_account_balance
      @mirror_account_balance ||= mirror_account_instance.balance
    end

    def account_balance_in_tenant_currency
      @account_balance_in_tenant_currency ||= account_instance.balance.convert_to(conversion_amount)
    end

    def revaluation_instance
      @revaluation_instance ||= Ledgerizer::Revaluation.find_or_create_by!(
        tenant_id: tenant.id,
        tenant_type: tenant.class.to_s,
        revaluation_time: revaluation_time,
        currency: conversion_currency
      )
    end

    def account_instance
      @account_instance ||= begin
        account = find_account_instance(
          mirror_currency: nil,
          account_currency: currency
        )

        if !account
          raise_error(
            "missing Ledgerizer::Account with name #{account_definition.name} and " +
              "currency #{currency}"
          )
        end

        account
      end
    end

    def mirror_account_instance
      @mirror_account_instance ||= begin
        account = find_account_instance(
          mirror_currency: currency,
          account_currency: conversion_amount.currency.to_s
        )

        if !account
          raise_error(
            "missing mirror Ledgerizer::Account with name #{account_definition.name} and " +
              "mirror_currency #{currency}"
          )
        end

        account
      end
    end

    def find_account_instance(mirror_currency:, account_currency:)
      Ledgerizer::Account.find_by(
        tenant_id: tenant.id,
        tenant_type: tenant.class.to_s,
        name: account_definition.name,
        accountable_id: accountable&.id,
        accountable_type: accountable.blank? ? nil : accountable.class.to_s,
        mirror_currency: mirror_currency,
        currency: account_currency
      )
    end

    def asset_revaluation?
      account_definition.asset?
    end

    def liability_revaluation?
      account_definition.liability?
    end

    def conversion_currency
      @conversion_currency ||= conversion_amount.currency.to_s
    end

    def get_conversion_amount!(amount)
      return if amount.blank?

      validate_money!(amount)
      validate_positive_money!(amount)

      if amount.currency.id != tenant.currency
        raise_error(
          "given currency (#{amount.currency.id}) must be the tenant's " +
            "currency (#{tenant.currency})"
        )
      end

      amount
    end

    def get_currency!(currency)
      validate_currency!(currency)

      format_currency(currency, strategy: :upcase, use_default: false)
    end

    def get_revaluation_time!(datetime)
      validate_datetime!(datetime)

      datetime
    end

    def get_account_definition!(tenant_definition, account_name)
      account = tenant_definition.accounts_by_name(account_name).first
      return account if account

      raise_error("can't find account with name: #{account_name}")
    end

    def get_revaluation_definition!(tenant_definition, revaluation_name)
      revaluation = tenant_definition.find_revaluation(revaluation_name)
      return revaluation if revaluation

      raise_error("can't find revaluation with name: #{revaluation_name}")
    end

    def get_accountable!(accountable)
      if accountable
        validate_ledgerized_instance!(
          accountable, "accountable", LedgerizerAccountable
        )
      end

      accountable
    end

    def get_tenant_definition!
      validate_ledgerized_instance!(tenant, "tenant", LedgerizerTenant)
      tenant_definition = config.find_tenant(tenant)
      return tenant_definition if tenant_definition

      raise_error("can't find tenant for given #{tenant.model_name} model")
    end
  end
end
