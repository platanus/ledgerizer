module Ledgerizer
  module Definition
    class Revaluation
      include Ledgerizer::Formatters

      attr_reader :name
      attr_reader :income_revaluation_account, :expense_revaluation_account
      attr_reader :positive_asset_entry_code, :negative_asset_entry_code
      attr_reader :positive_liability_entry_code, :negative_liability_entry_code

      def initialize(name:)
        @name = format_to_symbol_identifier(name)
        formatted_name = format_to_symbol_identifier(name)
        @income_revaluation_account = "positive_#{formatted_name}".to_sym
        @expense_revaluation_account = "negative_#{formatted_name}".to_sym
        @positive_asset_entry_code = "positive_#{formatted_name}_asset_revaluation".to_sym
        @negative_asset_entry_code = "negative_#{formatted_name}_asset_revaluation".to_sym
        @positive_liability_entry_code = "positive_#{formatted_name}_liability_revaluation".to_sym
        @negative_liability_entry_code = "negative_#{formatted_name}_liability_revaluation".to_sym
      end

      def add_account(account_name:, accountable:)
        account = Ledgerizer::Definition::RevaluationAccount.new(
          name: account_name,
          accountable: accountable
        )

        found_account = find_account(account)
        return found_account if found_account

        accounts << account
        account
      end

      def accounts
        @accounts ||= []
      end

      private

      def find_account(account)
        accounts.find do |acc|
          account.name == acc.name &&
            account.accountable == acc.accountable
        end
      end
    end
  end
end
