module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    delegate :new_movements, :add_new_movement, :related_accounts, :entry_instance,
      to: :executable_entry, prefix: false
    private :new_movements, :related_accounts, :entry_instance

    def initialize(config:, tenant:, document:, entry_code:, entry_time:, conversion_amount:)
      @executable_entry = Ledgerizer::Execution::Entry.new(
        config: config,
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_time: entry_time,
        conversion_amount: conversion_amount
      )
    end

    def execute
      validate_existent_movements!
      validate_zero_trial_balance!
      create_entry
      true
    end

    private

    attr_reader :executable_entry

    def create_entry
      Locking.lock_accounts(*related_accounts) do
        return if new_movements.none?

        entry_instance.lines.destroy_all if entry_instance.lines.any?
        locked_accounts = get_locked_accounts
        persist_movements!(locked_accounts)
        update_related_accounts_balances(locked_accounts)
      end
    end

    def update_related_accounts_balances(locked_accounts)
      locked_accounts.values.each do |locked_account|
        if locked_account.lines.none?
          locked_account.destroy!
          next
        end

        last_account_line = update_related_account_lines_balances(locked_account)
        locked_account.update(
          balance_cents: last_account_line.balance_cents,
          balance_currency: last_account_line.balance_currency
        )
      end
    end

    def update_related_account_lines_balances(locked_account)
      prev_line = last_prev_line_for_entry_time(locked_account)
      lines = lines_from_entry_time(locked_account).to_a.reverse

      lines.each do |line|
        balance = (prev_line&.balance || Money.new(0, line.amount.currency)) + line.amount
        line.balance_cents = balance.cents
        line.balance_currency = balance.currency
        line.save!
        prev_line = line
      end

      prev_line
    end

    def last_prev_line_for_entry_time(locked_account)
      locked_account.lines.filtered(entry_time_lt: entry_instance.entry_time).first
    end

    def lines_from_entry_time(locked_account)
      locked_account.lines.filtered(entry_time_gteq: entry_instance.entry_time)
    end

    def persist_movements!(locked_accounts)
      new_movements.each do |movement|
        locked_account = locked_accounts[movement.account_identifier]
        entry_instance.lines.create!(
          account: locked_account,
          amount_cents: movement.signed_amount_cents,
          amount_currency: movement.signed_amount_currency
        )
      end
    end

    def get_locked_accounts
      related_accounts.inject({}) do |result, executable_account|
        key = executable_account.identifier
        result[key] = Locking.account_instance_for_locked_executable_account(executable_account)
        result
      end
    end

    def validate_existent_movements!
      raise_error("can't execute entry without movements") if new_movements.none?
    end

    def validate_zero_trial_balance!
      raise_error("trial balance must be zero") unless zero_trial_balance?
    end

    def zero_trial_balance?
      new_movements.inject(0) do |sum, movement|
        amount = movement.signed_amount
        amount = -amount if movement.credit?
        sum += amount
        sum
      end.zero?
    end
  end
end
