module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    attr_reader :executable_entry

    def initialize(tenant:, document:, entry_code:, entry_date:)
      @executable_entry = Ledgerizer::Execution::Entry.new(
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    def add_credit(account_name:, accountable:, amount:)
      add_entry_account(credits, :credit, account_name, accountable, amount)
    end

    def add_debit(account_name:, accountable:, amount:)
      add_entry_account(debits, :debit, account_name, accountable, amount)
    end

    def credits
      @credits ||= []
    end

    def debits
      @debits ||= []
    end

    private

    def add_entry_account(collection, movement_type, account_name, accountable, amount)
      entry = Ledgerizer::Execution::EntryAccount.new(
        executable_entry: executable_entry,
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable,
        amount: amount
      )

      collection << entry
      entry
    end
  end
end
