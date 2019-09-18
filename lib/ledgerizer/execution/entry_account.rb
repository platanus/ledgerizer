module Ledgerizer
  module Execution
    class EntryAccount
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :amount, :currency, :accountable, :account_name

      def initialize(executable_entry:, account_type:, account_name:, accountable:, amount:)
        validate_input!(
          executable_entry: executable_entry,
          account_type: account_type,
          account_name: account_name,
          accountable: accountable,
          amount: amount
        )

        @amount = amount
        @currency = format_currency(amount.currency, strategy: :upcase, use_default: false)
        @accountable = accountable
        @account_name = format_to_symbol_identifier(account_name)
      end

      def to_hash
        {
          amount: amount,
          currency: currency,
          accountable: accountable,
          account_name: account_name
        }
      end

      private

      def validate_input!(executable_entry:, account_type:, account_name:, accountable:, amount:)
        validate_active_record_instance!(accountable, "accountable")
        validate_entry_account!(
          executable_entry.tenant,
          executable_entry.entry_code,
          account_type,
          account_name,
          accountable
        )
        validate_money!(amount)
        validate_tenant_currency!(executable_entry.tenant, amount.currency)
        validate_positive_money!(amount)
      end
    end
  end
end
