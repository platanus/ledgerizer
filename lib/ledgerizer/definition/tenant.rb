module Ledgerizer
  module Definition
    class Tenant
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :model_class_name

      def initialize(model_name:, currency: nil)
        model_name = format_to_symbol_identifier(model_name)
        validate_active_record_model_name!(model_name, "tenant name")
        @model_class_name = model_name
        formatted_currency = format_currency(currency)
        validate_currency!(formatted_currency)
        @currency = formatted_currency
      end

      def currency
        @currency || :usd
      end

      def add_account(name:, type:, contra: false)
        validate_unique_account!(name)
        Ledgerizer::Definition::Account.new(
          name: name, type: type, contra: contra, base_currency: currency
        ).tap do |account|
          @accounts << account
        end
      end

      def add_entry(code:, document:)
        validate_unique_entry!(code)
        Ledgerizer::Definition::Entry.new(code: code, document: document).tap do |entry|
          @entries << entry
        end
      end

      def add_debit(entry_code:, account_name:, accountable:)
        add_entry_account(:add_debit, entry_code, account_name, accountable)
      end

      def add_credit(entry_code:, account_name:, accountable:)
        add_entry_account(:add_credit, entry_code, account_name, accountable)
      end

      def find_account(name)
        find_in_collection(accounts, :name, name)
      end

      def find_entry(code)
        find_in_collection(entries, :code, code)
      end

      private

      def add_entry_account(entry_method, entry_code, account_name, accountable)
        validate_existent_entry!(entry_code)
        tenant_entry = find_entry(entry_code)
        validate_existent_account!(account_name)
        tenant_account = find_account(account_name)
        tenant_entry.send(entry_method, account: tenant_account, accountable: accountable)
      end

      def find_in_collection(collection, attribute, value)
        collection.find { |item| item.send(attribute).to_s.to_sym == value }
      end

      def accounts
        @accounts ||= []
      end

      def entries
        @entries ||= []
      end

      def validate_existent_account!(name)
        if !find_account(name)
          raise Ledgerizer::ConfigError.new(
            "the #{name} account does not exist in tenant"
          )
        end
      end

      def validate_existent_entry!(code)
        if !find_entry(code)
          raise Ledgerizer::ConfigError.new(
            "the #{code} entry does not exist in tenant"
          )
        end
      end

      def validate_unique_account!(account_name)
        if find_account(account_name)
          raise Ledgerizer::ConfigError.new(
            "the #{account_name} account already exists in tenant"
          )
        end
      end

      def validate_unique_entry!(code)
        if find_entry(code)
          raise Ledgerizer::ConfigError.new(
            "the #{code} entry already exists in tenant"
          )
        end
      end
    end
  end
end
