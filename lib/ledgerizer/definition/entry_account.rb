module Ledgerizer
  module Definition
    class EntryAccount
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :account, :accountable

      delegate :name, to: :account, prefix: true

      def initialize(account, accountable)
        @account = account
        class_model_name = format_to_symbol_identifier(accountable)
        validate_active_record_model_name!(class_model_name, "entry's accountable")
        @accountable = class_model_name
      end
    end
  end
end
