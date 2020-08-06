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
        account_currency = get_account_currency(currency)
        validate_unique_account!(name, account_currency)
        Ledgerizer::Definition::Account.new(
          name: name, type: type, contra: contra, currency: account_currency
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

      def find_entry(code)
        entries.find { |account| account.code == code }
      end

      def add_movement(movement_type:, entry_code:, account_name:, accountable:)
        validate_existent_entry!(entry_code)
        tenant_entry = find_entry(entry_code)

        movements = accounts_by_name(account_name).map do |account|
          tenant_entry.add_movement(
            movement_type: movement_type,
            account: account,
            accountable: accountable
          )
        end

        if movements.blank?
          raise_config_error("the #{account_name} account does not exist in tenant")
        end

        movements
      end

      private

      def accounts
        @accounts ||= []
      end

      def entries
        @entries ||= []
      end

      def find_account(account_name, account_currency)
        accounts.find do |account|
          account.name == account_name && account.currency == account_currency
        end
      end

      def accounts_by_name(name)
        accounts.select { |account| account.name == name }
      end

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

      def validate_existent_account!(account_name, account_currency)
        if !find_account(account_name, account_currency)
          raise_config_error(
            "the #{account_name} account with #{account_currency} currency does not exist in tenant"
          )
        end
      end

      def validate_existent_entry!(code)
        raise_config_error("the #{code} entry does not exist in tenant") unless find_entry(code)
      end

      def validate_unique_account!(account_name, account_currency)
        if find_account(account_name, account_currency)
          raise_config_error(
            "the #{account_name} account with #{account_currency} currency already exists in tenant"
          )
        end
      end

      def validate_unique_entry!(code)
        raise_config_error("the #{code} entry already exists in tenant") if find_entry(code)
      end
    end
  end
end
