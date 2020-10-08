module Ledgerizer
  module Definition
    class RevaluationEntiresCreator
      include Ledgerizer::Formatters
      include Ledgerizer::Validators

      def initialize(tenant:, revaluation:)
        @tenant = tenant
        @revaluation = revaluation
      end

      def create
        load_revaluation_data
        load_revaluation_accounts
        load_revaluation_entries
        true
      end

      private

      attr_reader :tenant, :revaluation

      def load_revaluation_accounts
        revaluable_currencies.each do |currency|
          add_revaluation_account(revaluation.income_revaluation_account, :income, currency)
          add_revaluation_account(revaluation.expense_revaluation_account, :expense, currency)
        end
      end

      def load_revaluation_entries
        create_asset_related_entries
        create_liability_related_entries
      end

      def create_asset_related_entries
        with_revaluation_accounts(:asset) do |accounts|
          add_revaluation_entry(
            entry_code: revaluation.positive_asset_entry_code,
            revaluation_account_name: revaluation.income_revaluation_account,
            revaluation_accounts: accounts,
            accounts_movement_type: :debit
          )

          add_revaluation_entry(
            entry_code: revaluation.negative_asset_entry_code,
            revaluation_account_name: revaluation.expense_revaluation_account,
            revaluation_accounts: accounts,
            accounts_movement_type: :credit
          )
        end
      end

      def create_liability_related_entries
        with_revaluation_accounts(:liability) do |accounts|
          add_revaluation_entry(
            entry_code: revaluation.positive_liability_entry_code,
            revaluation_account_name: revaluation.expense_revaluation_account,
            revaluation_accounts: accounts,
            accounts_movement_type: :debit
          )

          add_revaluation_entry(
            entry_code: revaluation.negative_liability_entry_code,
            revaluation_account_name: revaluation.income_revaluation_account,
            revaluation_accounts: accounts,
            accounts_movement_type: :credit
          )
        end
      end

      def with_revaluation_accounts(type, &block)
        accounts = revaluation_accounts_by_type[type]
        return if accounts.blank?

        block.call(accounts)
      end

      def add_revaluation_entry(
        entry_code:, revaluation_account_name:, revaluation_accounts:, accounts_movement_type:
      )
        tenant.add_entry(code: entry_code, document: :"ledgerizer/revaluation")
        tenant.add_movement(
          entry_code: entry_code,
          movement_type: accounts_movement_type == :credit ? :debit : :credit,
          account_name: revaluation_account_name, accountable: nil, mirror_only: true
        )
        revaluation_accounts.each do |account|
          tenant.add_movement(
            entry_code: entry_code,
            movement_type: accounts_movement_type,
            account_name: account.name, accountable: account.accountable, mirror_only: true
          )
        end
      end

      def add_revaluation_account(account_name, account_type, currency)
        tenant.add_mirror_account(
          name: account_name,
          type: account_type,
          currency: currency,
          contra: false
        )
      end

      def load_revaluation_data
        @revaluable_currencies = []
        revaluation_accounts.each do |rev_account|
          definition_accounts = tenant.accounts_by_name(rev_account.name)
          first_account = definition_accounts.first

          if first_account.blank?
            raise_config_error(
              "undefined #{rev_account.name} account for #{revaluation.name} revaluation"
            )
          end

          rev_account.type = valid_account_type(rev_account.name, first_account.type)
          @revaluable_currencies += valid_account_currencies(rev_account.name, definition_accounts)
        end
      end

      def valid_account_type(account_name, account_type)
        if ![:asset, :liability].include?(account_type)
          raise_config_error(
            "#{account_name} must be asset or liability to be revalued"
          )
        end

        account_type
      end

      def valid_account_currencies(account_name, definition_accounts)
        currencies = definition_accounts.map(&:mirror_currency).compact
        return currencies if currencies.any?

        raise_config_error(
          "only accounts with a currency other than the tenant can be revalued. " +
          "#{account_name} account currencies: " +
          "#{currencies.join(', ').presence || tenant.currency}. " +
          "tenant currency: #{tenant.currency}"
        )
      end

      def revaluable_currencies
        @revaluable_currencies.uniq.compact.reject do |currency|
          currency == tenant.currency
        end
      end

      def revaluation_accounts_by_type
        @revaluation_accounts_by_type ||= revaluation_accounts.group_by(&:type)
      end

      def revaluation_accounts
        @revaluation_accounts ||= begin
          accounts = revaluation.accounts
          if accounts.any?
            accounts
          else
            raise_config_error("missing revaluation accounts")
          end
        end
      end
    end
  end
end
