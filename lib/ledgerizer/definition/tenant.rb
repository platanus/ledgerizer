module Ledgerizer
  module Definition
    class Tenant
      include Ledgerizer::Formatters

      attr_reader :model_class

      def initialize(model_name, currency = nil)
        @model_class = infer_active_record_class!(model_name)
        @currency = format_currency!(currency)
      end

      def currency
        @currency || :usd
      end

      def add_account(name, type)
        validate_unique_account!(name)
        account = Ledgerizer::Definition::Account.new(name, type)
        @accounts << account
        account
      end

      def find_account(name)
        accounts.find { |account| account.name == name }
      end

      private

      def accounts
        @accounts ||= []
      end

      def validate_unique_account!(account_name)
        if find_account(account_name)
          raise Ledgerizer::ConfigError.new(
            "the #{account_name} account already exists in tenant"
          )
        end
      end
    end
  end
end
