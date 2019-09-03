module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    def initialize(tenant:, document:, entry_code:, entry_date:)
      validate_tenant_instance!(tenant, "tenant")
      @tenant = tenant
      validate_active_record_instance!(document, "document")
      @document = document
      code = format_to_symbol_identifier(entry_code)
      validate_tenant_entry!(tenant, code, document)
      @entry_code = code
      validate_date!(entry_date)
      @entry_date = entry_date.to_date
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

    def add_entry_account(collection, account_type, account_name, accountable, amount)
      validate_active_record_instance!(accountable, "accountable")
      validate_entry_account!(@tenant, @entry_code, account_type, account_name, accountable)
      validate_money!(amount)
      validate_tenant_currency!(@tenant, amount.currency)
      validate_positive_money!(amount)

      data = {
        amount: amount,
        currency: format_currency(amount.currency, strategy: :upcase, use_default: false),
        accountable: accountable,
        account_name: format_to_symbol_identifier(account_name)
      }

      collection << data
      data
    end
  end
end
