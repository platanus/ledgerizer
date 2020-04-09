module Ledgerizer
  module Execution
    class Movement
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :accountable, :movement_definition
      attr_accessor :amount

      delegate :credit?, :debit?, :contra, :base_currency,
               :movement_type, :account_name, :account_type,
               to: :movement_definition, prefix: false

      def initialize(movement_definition:, accountable:, amount:, allow_negative_amount: false)
        @allow_negative_amount = allow_negative_amount
        @movement_definition = movement_definition
        validate_amount!(amount)

        @amount = amount
        @accountable = accountable
      end

      def ==(other)
        movement_definition == other.movement_definition &&
          accountable == other.accountable
      end

      def signed_amount
        if movement_type == :debit
          debit? && !contra ? amount : -amount
        else
          credit? && !contra ? amount : -amount
        end
      end

      def signed_amount_cents
        signed_amount&.cents
      end

      def signed_amount_currency
        signed_amount&.currency
      end

      private

      attr_reader :allow_negative_amount

      def validate_amount!(amount)
        validate_money!(amount)
        validate_account_currency!(amount.currency)
        validate_positive_money!(amount) unless allow_negative_amount
      end

      def validate_account_currency!(currency)
        if base_currency != format_to_symbol_identifier(currency)
          raise_error("#{currency} is not the account's currency")
        end
      end
    end
  end
end
