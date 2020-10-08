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

      def add_account(name:, type:, account_currency: nil, contra: false)
        inferred_currency = account_or_tenant_currency(account_currency)
        account_config = {
          name: name,
          type: type,
          contra: contra,
          currency: inferred_currency,
          mirror_currency: nil
        }
        new_account = add_main_account(account_config)
        add_mirror_account(account_config) if inferred_currency != currency
        new_account
      end

      def add_entry(code:, document:)
        validate_unique_entry!(code)
        Ledgerizer::Definition::Entry.new(code: code, document: document).tap do |entry|
          entries << entry
        end
      end

      def find_entry(code)
        entries.find { |entry| entry.code == code }
      end

      def add_movement(movement_type:, entry_code:, account_name:, accountable:, mirror_only: false)
        validate_existent_entry!(entry_code)
        tenant_entry = find_entry(entry_code)

        movements = accounts_by_name(account_name).map do |account|
          next if mirror_only && account.mirror_currency.blank?

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

      def add_revaluation(name:)
        validate_unique_revaluation!(name)
        Ledgerizer::Definition::Revaluation.new(name: name).tap do |revaluation|
          revaluations << revaluation
        end
      end

      def accounts_by_name(name)
        accounts.select { |account| account.name == name }
      end

      def add_mirror_account(main_account_config)
        mirror_account_config = main_account_config.dup
        mirror_account_config[:mirror_currency] = main_account_config[:currency]
        mirror_account_config[:currency] = currency
        add_account_to_collection(mirror_account_config)
      end

      private

      def find_revaluation(name)
        revaluations.find { |revaluation| revaluation.name == name }
      end

      def add_main_account(account_config)
        add_account_to_collection(account_config)
      end

      def add_account_to_collection(account_config)
        Ledgerizer::Definition::Account.new(account_config).tap do |account|
          validate_unique_account!(account)
          accounts << account
        end
      end

      def accounts
        @accounts ||= []
      end

      def entries
        @entries ||= []
      end

      def revaluations
        @revaluations ||= []
      end

      def find_account(account_name, account_currency, mirror_currency)
        accounts.find do |tenant_account|
          tenant_account.name == account_name &&
            tenant_account.currency == account_currency &&
            tenant_account.mirror_currency == mirror_currency
        end
      end

      def account_or_tenant_currency(account_currency)
        return currency if account_currency.blank?

        formatted_currency = format_currency(
          account_currency,
          strategy: :symbol,
          use_default: false
        )
        validate_currency!(formatted_currency)
        formatted_currency
      end

      def validate_existent_entry!(code)
        raise_config_error("the #{code} entry does not exist in tenant") unless find_entry(code)
      end

      def validate_unique_account!(account)
        if find_account(account.name, account.currency, account.mirror_currency)
          raise_config_error(
            "the #{account.name} account with #{account.currency} currency \
and #{account.mirror_currency.presence || 'no'} mirror currency already exists in tenant"
          )
        end
      end

      def validate_unique_entry!(code)
        raise_config_error("the #{code} entry already exists in tenant") if find_entry(code)
      end

      def validate_unique_revaluation!(name)
        if find_revaluation(name)
          raise_config_error("the #{name} revaluation already exists in tenant")
        end
      end
    end
  end
end
