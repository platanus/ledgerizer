module Ledgerizer
  module Definition
    class Movement
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :account, :accountable, :movement_type

      delegate :name, :type, :currency, to: :account, prefix: true
      delegate :credit?, :debit?, :contra, :mirror_currency, to: :account, prefix: false

      def initialize(account:, accountable:, movement_type:)
        @account = account
        @movement_type = format_to_symbol_identifier(movement_type)
        @accountable = format_to_symbol_identifier(accountable) if accountable
      end

      def accountable_class
        return unless accountable

        format_string_to_class(accountable)
      end

      def accountable_string_class
        return unless accountable

        accountable_class.to_s
      end
    end
  end
end
