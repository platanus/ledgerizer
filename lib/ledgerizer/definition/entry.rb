module Ledgerizer
  module Definition
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters
      include Ledgerizer::Common

      attr_reader :code, :document

      def initialize(code:, document:)
        @code = format_to_symbol_identifier(code)
        document_class_name = format_to_symbol_identifier(document)
        validate_ledgerized_class_name!(document_class_name, "entry's document", LedgerizerDocument)
        @document = document_class_name
      end

      def find_movement(
        movement_type:, account_name:, account_currency:, mirror_currency:, accountable:
      )
        movements.find do |movement|
          movement.account_name == account_name &&
            movement.account_currency == account_currency &&
            movement.mirror_currency == mirror_currency &&
            movement.movement_type == movement_type &&
            movement.accountable == infer_ledgerized_class_name(accountable)
        end
      end

      def add_movement(movement_type:, account:, accountable:)
        active_record_accountable = find_active_record_accountable(
          movement_type, account, accountable
        )

        Ledgerizer::Definition::Movement.new(
          account: account,
          accountable: active_record_accountable,
          movement_type: movement_type
        ).tap do |movement|
          movements << movement
        end
      end

      def movements
        @movements ||= []
      end

      private

      def find_active_record_accountable(movement_type, account, accountable)
        accountable_class_name = nil

        if accountable.present?
          accountable_class_name = format_to_symbol_identifier(accountable)
          validate_ledgerized_class_name!(
            accountable_class_name, "accountable", LedgerizerAccountable
          )
        end

        validate_unique_account!(movement_type, account, accountable_class_name)
        accountable_class_name
      end

      def validate_unique_account!(movement_type, account, accountable)
        if find_movement(
          movement_type: movement_type,
          account_name: account.name,
          account_currency: account.currency,
          mirror_currency: account.mirror_currency,
          accountable: accountable
        )
          raise_config_error(
            "movement with account #{account.name}, #{account.currency} currency " +
              "(#{account.mirror_currency || 'NO'} mirror currency) and " +
              "accountable #{accountable} already exists in tenant"
          )
        end
      end
    end
  end
end
