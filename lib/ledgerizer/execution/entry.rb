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

      def add_entry_account(movement_type:, account_name:, accountable:, amount:)
        entry_account_def = get_entry_account_definition!(movement_type, account_name, accountable)
        entry = Ledgerizer::Execution::EntryAccount.new(
          entry_account_definition: entry_account_def,
          accountable: accountable,
          amount: amount
        )

        entry_accounts << entry
        entry
      end

      def entry_accounts
        @entry_accounts ||= []
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

      def get_entry_account_definition!(movement_type, account_name, accountable)
        validate_active_record_instance!(accountable, "accountable")
        entry_account_def = entry_definition.find_entry_account(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
        return entry_account_def if entry_account_def

        raise_validation_error(
          "invalid entry account #{account_name} with accountable " +
            "#{accountable.class} for given #{entry_definition.code} " +
            "entry in #{movement_type.to_s.pluralize}"
        )
      end
    end
  end
end
