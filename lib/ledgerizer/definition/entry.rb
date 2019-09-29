module Ledgerizer
  module Definition
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :code, :document

      def initialize(code:, document:)
        @code = format_to_symbol_identifier(code)
        document_model_name = format_to_symbol_identifier(document)
        validate_active_record_model_name!(document_model_name, "entry's document")
        @document = document_model_name
      end

      def find_movement(movement_type:, account_name:, accountable:)
        movements.find do |movement|
          movement.account_name == account_name &&
            movement.movement_type == movement_type &&
            movement.accountable == infer_model_name(accountable)
        end
      end

      def add_movement(movement_type:, account:, accountable:)
        ar_accountable = format_to_symbol_identifier(accountable)
        validate_active_record_model_name!(ar_accountable, "accountable")
        validate_unique_account!(movement_type, account.name, ar_accountable)

        Ledgerizer::Definition::Movement.new(
          account: account,
          accountable: ar_accountable,
          movement_type: movement_type
        ).tap do |movement|
          movements << movement
        end
      end

      def movements
        @movements ||= []
      end

      private

      def infer_model_name(value)
        return format_model_to_sym(value) if value.is_a?(ActiveRecord::Base)

        value
      end

      def validate_unique_account!(movement_type, account_name, accountable)
        if find_movement(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
          raise_config_error(
            "movement #{account_name} with accountable #{accountable} already exists in tenant"
          )
        end
      end
    end
  end
end
