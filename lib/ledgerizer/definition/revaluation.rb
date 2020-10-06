module Ledgerizer
  module Definition
    class Revaluation
      include Ledgerizer::Formatters

      attr_reader :name
      attr_reader :income_revaluation_account, :expense_revaluation_account

      def initialize(name:)
        @name = format_to_symbol_identifier(name)
        @income_revaluation_account = format_to_symbol_identifier("positive_#{name}")
        @expense_revaluation_account = format_to_symbol_identifier("negative_#{name}")
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
