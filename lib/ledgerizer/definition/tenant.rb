module Ledgerizer
  module Definition
    class Tenant
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
          raise_error("the #{account_name} account already exists in tenant")
        end
      end

      def infer_active_record_class!(model_name)
        model_name.to_s.classify.constantize
      rescue NameError
        raise_error("tenant name must be an ActiveRecord model name")
      end

      def format_currency!(currency)
        formatted_currency = currency.to_s.downcase.to_sym
        return :usd if formatted_currency.blank?
        return formatted_currency if Money::Currency.table.key?(formatted_currency)

        raise_error("invalid currency '#{currency}' given")
      end

      def raise_error(msg)
        raise Ledgerizer::ConfigError.new(msg)
      end
    end
  end
end
