module Ledgerizer
  module Definition
    class EntryAccount
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :account, :accountable, :movement_type

      delegate :name, to: :account, prefix: true
      delegate :credit?, :debit?, to: :account, prefix: false

      def initialize(account:, accountable:, movement_type:)
        @account = account
        @movement_type = format_to_symbol_identifier(movement_type)
        class_model_name = format_to_symbol_identifier(accountable)
        validate_active_record_model_name!(class_model_name, "entry's accountable")
        @accountable = class_model_name
      end
    end
  end
end
