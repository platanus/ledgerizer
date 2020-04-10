module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    delegate :new_movements, :adjusted_movements, :add_new_movement,
             :related_accounts, :entry_date, :entry_instance,
             to: :executable_entry, prefix: false

    def initialize(config:, tenant:, document:, entry_code:, entry_date:)
      @executable_entry = Ledgerizer::Execution::Entry.new(
        config: config,
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    def execute
      validate_existent_movements!
      validate_zero_trial_balance!(new_movements)
      create_entry
      true
    end

    private

    attr_reader :executable_entry

    def create_entry
      Locking.lock_accounts(*related_accounts) do
        return if adjusted_movements.none?

        locked_accounts = get_locked_accounts
        last_entry_date = entry_instance.entry_date || entry_date
        persist_new_movements!
        locked_accounts.each do |locked_account|
          last_account_line = update_account_related_lines_balances(
            last_entry_date,
            locked_account
          )
          locked_account.balance = last_account_line.balance
          locked_account.save!
        end
      end
    end

    def update_account_related_lines_balances(last_entry_date, locked_account)
      prev_line = last_prev_line_for_entry_date(locked_account, last_entry_date)
      lines = lines_from_entry_date(locked_account, last_entry_date).to_a.reverse

      lines.each do |line|
        line.balance = (prev_line&.balance || Money.new(0, line.amount.currency)) + line.amount
        line.save!
        prev_line = line
      end

      prev_line
    end

    def last_prev_line_for_entry_date(locked_account, last_entry_date)
      locked_account.lines.filtered(entry_date_lt: last_entry_date).first
    end

    def lines_from_entry_date(locked_account, last_entry_date)
      locked_account.lines.filtered(entry_date_gteq: last_entry_date)
    end

    def persist_new_movements!
      validate_zero_trial_balance!(adjusted_movements)
      entry_instance.entry_date = entry_date
      entry_instance.save!
      adjusted_movements.each do |movement|
        entry_instance.create_line!(movement)
      end
    end

    def get_locked_accounts
      related_accounts.map do |executable_account|
        Locking.account_instance_for_locked_executable_account(executable_account)
      end
    end

    def validate_existent_movements!
      raise_error("can't execute entry without movements") if new_movements.none?
    end

    def validate_zero_trial_balance!(movements)
      raise_error("trial balance must be zero") unless zero_trial_balance?(movements)
    end

    def zero_trial_balance?(movements)
      movements.inject(0) do |sum, movement|
        amount = movement.signed_amount
        amount = -amount if movement.credit?
        sum += amount
        sum
      end.zero?
    end
  end
end
