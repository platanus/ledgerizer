module Ledgerizer
  module Execution
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :document, :entry_date

      def initialize(entry_definition:, document:, entry_date:)
        @entry_definition = entry_definition
        validate_entry_document!(document)
        @document = document
        validate_date!(entry_date)
        @entry_date = entry_date.to_date
      end

      def add_movement(movement_type:, account_name:, accountable:, amount:)
        movement_definition = get_movement_definition!(movement_type, account_name, accountable)
        entry = Ledgerizer::Execution::Movement.new(
          movement_definition: movement_definition,
          accountable: accountable,
          amount: amount
        )

        movements << entry
        entry
      end

      def movements
        @movements ||= []
      end

      private

      attr_reader :entry_definition

      def validate_entry_document!(document)
        validate_active_record_instance!(document, "document")

        if format_model_to_sym(document) != entry_definition.document
          raise_validation_error(
            "invalid document #{document.class} for given #{entry_definition.code} entry"
          )
        end
      end

      def get_movement_definition!(movement_type, account_name, accountable)
        validate_active_record_instance!(accountable, "accountable")
        movement_definition = entry_definition.find_movement(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
        return movement_definition if movement_definition

        raise_validation_error(
          "invalid movement #{account_name} with accountable " +
            "#{accountable.class} for given #{entry_definition.code} " +
            "entry in #{movement_type.to_s.pluralize}"
        )
      end
    end
  end
end