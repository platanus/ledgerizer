module Ledgerizer
  module Definition
    class EntryAccount
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :account, :accountable, :movement_type

      delegate :name, to: :account, prefix: true
      delegate :credit?, :debit?, :base_currency, to: :account, prefix: false

      def initialize(account:, accountable:, movement_type:)
        @account = account
        @movement_type = format_to_symbol_identifier(movement_type)
        @accountable = format_to_symbol_identifier(accountable)
      end
    end
  end
end
