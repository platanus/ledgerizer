module Ledgerizer
  module Execution
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :document, :entry_time

      def initialize(config:, tenant:, document:, entry_code:, entry_time:, conversion_amount:)
        @tenant_definition = get_tenant_definition!(config, tenant)
        @tenant = tenant
        @entry_definition = get_entry_definition!(@tenant_definition, entry_code)
        @conversion_amount = get_conversion_amount!(conversion_amount)
        validate_entry_document!(document)
        @document = document
        validate_datetime!(entry_time)
        @entry_time = entry_time.to_datetime
      end

      def add_new_movement(
        movement_type:, account_name:, accountable:, amount:, mirror_currency: nil
      )
        validate_money!(amount)
        validate_accountable!(accountable)
        calculated_amount = calculate_amount(amount)
        mirror_currency = get_movement_mirror_currency(amount, mirror_currency)
        movement_definition = get_movement_definition!(
          movement_type, account_name, accountable, calculated_amount, mirror_currency
        )
        movement = Ledgerizer::Execution::Movement.new(
          movement_definition: movement_definition,
          accountable: accountable,
          amount: calculated_amount
        )

        new_movements << movement
        movement
      end

      def entry_instance
        @entry_instance ||= find_or_create_entry_instance
      end

      def new_movements
        @new_movements ||= []
      end

      def related_accounts
        @related_accounts ||= begin
          (accounts_from_new_movements + accounts_from_entry_instance).inject([]) do |memo, account|
            memo << account unless memo.include?(account)
            memo
          end
        end
      end

      private

      attr_reader :entry_definition, :tenant_definition, :tenant, :conversion_amount

      def find_or_create_entry_instance
        entry = tenant.entries.find_by(find_entry_params)
        return entry if entry

        Ledgerizer::Entry.create!(create_entry_params)
      end

      def accounts_from_new_movements
        new_movements.map do |movement|
          account = Ledgerizer::Execution::Account.new(
            tenant_id: tenant.to_id_attr,
            tenant_type: tenant.to_type_attr,
            accountable_id: movement.accountable&.to_id_attr,
            accountable_type: movement.accountable&.to_type_attr,
            account_name: movement.account_name.to_sym,
            account_type: movement.account_type.to_sym,
            currency: movement.signed_amount_currency.to_s,
            mirror_currency: movement.upcase_mirror_currency
          )
          movement.account_identifier = account.identifier
          account
        end
      end

      def accounts_from_entry_instance
        entry_instance.accounts.to_a.map do |account|
          Ledgerizer::Execution::Account.new(
            tenant_id: tenant.to_id_attr,
            tenant_type: tenant.to_type_attr,
            accountable_id: account.accountable_id,
            accountable_type: account.accountable_type,
            account_name: account.name.to_sym,
            account_type: get_movement_definition_from_account(account).account_type.to_sym,
            currency: account.balance_currency,
            mirror_currency: account.mirror_currency
          )
        end
      end

      def find_entry_params
        @find_entry_params ||= begin
          {
            code: entry_definition.code,
            tenant_id: tenant.to_id_attr,
            tenant_type: tenant.to_type_attr,
            document_id: document.to_id_attr,
            document_type: document.to_type_attr,
            entry_time: entry_time,
            mirror_currency: get_entry_mirror_currency
          }
        end
      end

      def create_entry_params
        @create_entry_params ||= begin
          if conversion_amount.blank?
            find_entry_params
          else
            conversion_amount_data = {
              conversion_amount_cents: conversion_amount_cents,
              conversion_amount_currency: conversion_amount_currency
            }

            find_entry_params.merge(conversion_amount_data)
          end
        end
      end

      def calculate_amount(original_amount)
        return original_amount if conversion_amount.blank?

        validate_amount_currency_different_from_conversion_amount_currency!(original_amount)
        original_amount.convert_to(conversion_amount)
      end

      def get_conversion_amount!(amount)
        return if amount.blank?

        validate_money!(amount)
        validate_conversion_amount_currency!(amount)
        validate_positive_money!(amount)
        amount
      end

      def conversion_amount_cents
        conversion_amount&.cents
      end

      def conversion_amount_currency
        return if conversion_amount.blank?

        conversion_amount.currency.to_s
      end

      def get_movement_mirror_currency(amount, mirror_currency)
        currency_format = { strategy: :symbol, use_default: false }
        return format_currency(mirror_currency, currency_format) if mirror_currency
        return if conversion_amount.blank?

        format_currency(amount.currency.to_s, currency_format)
      end

      def get_entry_mirror_currency
        mirror_currencies = accounts_from_new_movements.map(&:mirror_currency).uniq
        raise_error("accounts with mixed mirror currency") if mirror_currencies.count > 1
        mirror_currencies.first
      end

      def validate_entry_document!(document)
        validate_ledgerized_instance!(document, "document", LedgerizerDocument)

        if format_ledgerizer_instance_to_sym(document) != entry_definition.document
          raise_error("invalid document #{document.class} for given #{entry_definition.code} entry")
        end
      end

      def get_movement_definition!(
        movement_type, account_name, accountable, amount, mirror_currency
      )
        account_currency = format_currency(amount.currency.to_s, strategy: :symbol)
        movement_definition = entry_definition.find_movement(
          account_name: account_name, movement_type: movement_type, accountable: accountable,
          account_currency: account_currency, mirror_currency: mirror_currency
        )
        return movement_definition if movement_definition

        raise_invalid_movement_error(
          movement_type: movement_type,
          entry_definition: entry_definition,
          account_name: account_name,
          account_currency: account_currency,
          mirror_currency: mirror_currency,
          accountable: accountable
        )
      end

      def validate_accountable!(accountable)
        if accountable
          validate_ledgerized_instance!(
            accountable, "accountable", LedgerizerAccountable
          )
        end
      end

      def get_movement_definition_from_account(account)
        %i{debit credit}.map do |movement_type|
          entry_definition.find_movement(
            movement_type: movement_type,
            account_name: format_to_symbol_identifier(account.name),
            account_currency: format_currency(account.currency, strategy: :symbol),
            mirror_currency: format_currency(
              account.mirror_currency, strategy: :symbol, use_default: false
            ),
            accountable: format_to_symbol_identifier(account.accountable_type)
          )
        end.compact.first
      end

      def get_tenant_definition!(config, tenant)
        validate_ledgerized_instance!(tenant, "tenant", LedgerizerTenant)
        tenant_definition = config.find_tenant(tenant)
        return tenant_definition if tenant_definition

        raise_error("can't find tenant for given #{tenant.model_name} model")
      end

      def get_entry_definition!(tenant_definition, entry_code)
        code = format_to_symbol_identifier(entry_code)
        entry_definition = tenant_definition.find_entry(code)
        return entry_definition if entry_definition

        raise_error("invalid entry code #{entry_code} for given tenant")
      end

      def validate_conversion_amount_currency!(amount)
        return if amount.currency.id == tenant_definition.currency

        raise_error(
          "conversion amount currency (#{amount.currency.id}) " +
            "is not the tenant's currency (#{tenant_definition.currency})"
        )
      end

      def validate_amount_currency_different_from_conversion_amount_currency!(amount)
        return if amount.currency.id != conversion_amount.currency.id

        raise_error(
          "the amount currency (#{amount.currency.id}) " +
            "can't be the same as conversion amount currency"
        )
      end

      def raise_invalid_movement_error(
        movement_type:, entry_definition:, account_name:, accountable:,
        account_currency:, mirror_currency:
      )
        raise_error(
          "invalid movement with account: #{account_name}, accountable: " +
            "#{accountable.class} and currency: #{account_currency} " +
            "(#{mirror_currency.presence || 'NO'} mirror currency) for given " +
            "#{entry_definition.code} entry in #{movement_type.to_s.pluralize}"
        )
      end
    end
  end
end
