module Ledgerizer
  module Definition
    class Tenant
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :model_name, :currency

      def initialize(model_name:, currency: nil)
        model_name = format_to_symbol_identifier(model_name)
        validate_ledgerized_class_name!(model_name, "tenant name", LedgerizerTenant)
        @model_name = model_name
        formatted_currency = format_currency(currency, strategy: :symbol, use_default: true)
        validate_currency!(formatted_currency)
        @currency = formatted_currency
      end

      def add_account(name:, type:, currency: nil, contra: false)
        validate_unique_account!(name)
        Ledgerizer::Definition::Account.new(
          name: name, type: type, contra: contra, currency: get_account_currency(currency)
        ).tap do |account|
          accounts << account
        end
      end

      def add_entry(code:, document:)
        validate_unique_entry!(code)
        Ledgerizer::Definition::Entry.new(code: code, document: document).tap do |entry|
          entries << entry
        end
      end

      def find_account(name)
        find_in_collection(accounts, :name, name)
      end

      def find_entry(code)
        find_in_collection(entries, :code, code)
      end

      def add_movement(movement_type:, entry_code:, account_name:, accountable:)
        validate_existent_entry!(entry_code)
        tenant_entry = find_entry(entry_code)
        validate_existent_account!(account_name)
        tenant_account = find_account(account_name)
        tenant_entry.add_movement(
          movement_type: movement_type, account: tenant_account, accountable: accountable
        )
      end

      def accounts_names
        accounts.map(&:name)
      end

      def accounts
        @accounts ||= []
      end

      def entries
        @entries ||= []
      end

      private

      def get_account_currency(account_currency)
        return currency if account_currency.blank?

        formatted_currency = format_currency(
          account_currency,
          strategy: :symbol,
          use_default: false
        )
        validate_currency!(formatted_currency)
        formatted_currency
      end

      def find_in_collection(collection, attribute, value)
        collection.find { |item| item.send(attribute).to_s.to_sym == value }
      end

      def validate_existent_account!(name)
        raise_config_error("the #{name} account does not exist in tenant") unless find_account(name)
      end

      def validate_existent_entry!(code)
        raise_config_error("the #{code} entry does not exist in tenant") unless find_entry(code)
      end

      def validate_unique_account!(account_name)
        if find_account(account_name)
          raise_config_error("the #{account_name} account already exists in tenant")
        end
      end

      def validate_unique_entry!(code)
        raise_config_error("the #{code} entry already exists in tenant") if find_entry(code)
      end
    end
  end
end
