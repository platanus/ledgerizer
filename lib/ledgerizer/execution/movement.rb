module Ledgerizer
  module Execution
    class Movement
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :accountable, :amount

      delegate :credit?, :debit?, :contra, :base_currency,
               :movement_type, :account_name, :account_type,
               to: :movement_definition, prefix: false

      def initialize(movement_definition:, accountable:, amount:)
        @movement_definition = movement_definition
        validate_amount!(amount)

        @amount = amount
        @currency = format_currency(amount.currency, strategy: :upcase, use_default: false)
        @accountable = accountable
      end

      def signed_amount
        if movement_type == :debit
          debit? && !contra ? amount : -amount
        else
          credit? && !contra ? amount : -amount
        end
      end

      private

      attr_reader :movement_definition

      def validate_amount!(amount)
        validate_money!(amount)
        validate_account_currency!(amount.currency)
        validate_positive_money!(amount)
      end

      def validate_account_currency!(currency)
        if base_currency != format_to_symbol_identifier(currency)
          raise_error("#{currency} is not the account's currency")
        end
      end
    end
  end
end
