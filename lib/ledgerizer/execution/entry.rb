module Ledgerizer
  module Execution
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :document, :entry_date

      delegate :code, to: :entry_definition, prefix: false

      def initialize(entry_definition:, document:, entry_date:)
        @entry_definition = entry_definition
        validate_entry_document!(document)
        @document = document
        validate_date!(entry_date)
        @entry_date = entry_date.to_date
      end

      def add_new_movement(movement_type:, account_name:, accountable:, amount:)
        movement_definition = get_movement_definition!(movement_type, account_name, accountable)
        movement = Ledgerizer::Execution::Movement.new(
          movement_definition: movement_definition,
          accountable: accountable,
          amount: amount
        )

        new_movements << movement
        movement
      end

      def old_movements(entry)
        found_movements = []

        for_each_grouped_by_accountable_and_currency_movement(entry) do |movement|
          found_movements << Ledgerizer::Execution::Movement.new(movement)
        end

        found_movements
      end

      def new_movements
        @new_movements ||= []
      end

      private

      attr_reader :entry_definition

      def for_each_grouped_by_accountable_and_currency_movement(entry, &block)
        entry_definition.movements.each do |movement_definition|
          groups = amounts_grouped_by_accountable_and_currency(entry, movement_definition)
          groups.each do |accountabe_data, amount_cents|
            accountable_id, currency = accountabe_data
            accountable = movement_definition.accountable_class&.find(accountable_id)

            block.call(
              accountable: accountable,
              movement_definition: movement_definition,
              amount: Money.new(amount_cents, currency),
              allow_negative_amount: true
            )
          end
        end
      end

      def amounts_grouped_by_accountable_and_currency(entry, movement_definition)
        attrs = %i{accountable_id amount_currency}
        lines_by_movement_definition(
          entry, movement_definition
        ).select(*attrs).group(*attrs).sum(:amount_cents)
      end

      def lines_by_movement_definition(entry, movement_definition)
        Ledgerizer::Line.where(
          tenant: entry.tenant,
          entry_code: code,
          document: entry.document,
          accountable_type: movement_definition.accountable_string_class,
          account_name: movement_definition.account_name
        )
      end

      def validate_entry_document!(document)
        validate_active_record_instance!(document, "document")

        if format_model_to_sym(document) != entry_definition.document
          raise_error("invalid document #{document.class} for given #{entry_definition.code} entry")
        end
      end

      def get_movement_definition!(movement_type, account_name, accountable)
        validate_active_record_instance!(accountable, "accountable") if accountable
        movement_definition = entry_definition.find_movement(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
        return movement_definition if movement_definition

        raise_error(
          "invalid movement #{account_name} with accountable " +
            "#{accountable.class} for given #{entry_definition.code} " +
            "entry in #{movement_type.to_s.pluralize}"
        )
      end
    end
  end
end
