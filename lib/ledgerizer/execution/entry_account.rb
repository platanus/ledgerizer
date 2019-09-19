module Ledgerizer
  module Execution
    class EntryAccount
      include Ledgerizer::Validators
      include Ledgerizer::Formatters
      include Ledgerizer::ConfigHelpers

      attr_reader :executable_entry, :amount, :currency, :accountable, :account_name, :movement_type

      delegate :credit?, :debit?, :contra, to: :account_definition, prefix: false

      def initialize(executable_entry:, movement_type:, account_name:, accountable:, amount:)
        @executable_entry = executable_entry

        validate_input!(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable,
          amount: amount
        )

        @movement_type = movement_type
        @amount = amount
        @currency = format_currency(amount.currency, strategy: :upcase, use_default: false)
        @accountable = accountable
        @account_name = format_to_symbol_identifier(account_name)
      end

      def signed_amount
        if movement_type == :debit
          debit? && !contra ? amount : -amount
        else
          credit? && !contra ? amount : -amount
        end
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

      def validate_input!(movement_type:, account_name:, accountable:, amount:)
        validate_active_record_instance!(accountable, "accountable")
        validate_entry_account!(tenant, entry_code, movement_type, account_name, accountable)
        validate_money!(amount)
        validate_tenant_currency!(tenant, amount.currency)
        validate_positive_money!(amount)
      end

      def account_definition
        account_conf(tenant, account_name)
      end

      def tenant
        executable_entry.tenant
      end

      def entry_code
        executable_entry.entry_code
      end
    end
  end
end
