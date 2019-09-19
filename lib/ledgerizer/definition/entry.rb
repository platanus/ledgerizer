module Ledgerizer
  module Definition
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :code, :document

      def initialize(code:, document:)
        @code = format_to_symbol_identifier(code)
        class_model_name = format_to_symbol_identifier(document)
        validate_active_record_model_name!(class_model_name, "entry's document")
        @document = class_model_name
      end

      def find_entry_account(movement_type:, account_name:, accountable:)
        entry_accounts.find do |entry_account|
          entry_account.account_name == account_name &&
            entry_account.movement_type == movement_type &&
            entry_account.accountable == infer_model_class_name(accountable)
        end
      end

      def add_entry_account(movement_type:, account:, accountable:)
        ar_accountable = format_to_symbol_identifier(accountable)
        validate_active_record_model_name!(ar_accountable, "accountable")
        validate_unique_account!(movement_type, account.name, ar_accountable)

        Ledgerizer::Definition::EntryAccount.new(
          account: account,
          accountable: ar_accountable,
          movement_type: movement_type
        ).tap do |entry_account|
          entry_accounts << entry_account
        end
      end

      def entry_accounts
        @entry_accounts ||= []
      end

      private

      def infer_model_class_name(value)
        return format_model_to_sym(value) if value.is_a?(ActiveRecord::Base)

        value
      end

      def validate_unique_account!(movement_type, account_name, accountable)
        if find_entry_account(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
          raise Ledgerizer::ConfigError.new(
            "entry account #{account_name} with accountable #{accountable} already exists in tenant"
          )
        end
      end
    end
  end
end
