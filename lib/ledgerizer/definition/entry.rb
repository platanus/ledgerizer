module Ledgerizer
  module Definition
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :code, :document

      def initialize(code, document)
        @code = format_to_symbol_identifier(code)
        class_model_name = format_to_symbol_identifier(document)
        validate_active_record_model_name!(class_model_name, "entry's document")
        @document = class_model_name
      end

      def add_debit(account, accountable)
        add_entry_account(debits, account, accountable)
      end

      def add_credit(account, accountable)
        add_entry_account(credits, account, accountable)
      end

      def find_credit(account_name, accountable)
        find_entry_account(credits, account_name, accountable)
      end

      def find_debit(account_name, accountable)
        find_entry_account(debits, account_name, accountable)
      end

      def find_entry_account(collection, account_name, accountable)
        collection.find do |entry_account|
          entry_account.account_name == account_name &&
            entry_account.accountable == infer_model_class_name(accountable)
        end
      end

      def debits
        @debits ||= []
      end

      def credits
        @credits ||= []
      end

      private

      def infer_model_class_name(value)
        return format_model_to_sym(value) if value.is_a?(ActiveRecord::Base)

        value
      end

      def add_entry_account(collection, account, accountable)
        ar_accountable = format_to_symbol_identifier(accountable)
        validate_active_record_model_name!(ar_accountable, "accountable")
        validate_unique_account!(collection, account.name, ar_accountable)

        Ledgerizer::Definition::EntryAccount.new(account, ar_accountable).tap do |entry_account|
          collection << entry_account
        end
      end

      def validate_unique_account!(collection, account_name, accountable)
        if find_entry_account(collection, account_name, accountable)
          raise Ledgerizer::ConfigError.new(
            "entry account #{account_name} with accountable #{accountable} already exists in tenant"
          )
        end
      end
    end
  end
end
