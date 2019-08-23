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
        Ledgerizer::Definition::Account.new(name, type).tap do |account|
          @accounts << account
        end
      end

      def add_entry(code, document)
        validate_unique_entry!(code)
        Ledgerizer::Definition::Entry.new(code, infer_active_record_class!(document)).tap do |entry|
          @entries << entry
        end
      end

      def find_account(name)
        accounts.find { |account| account.name == name }
      end

      def find_entry(code)
        entries.find { |entry| entry.code == code }
      end

      private

      def accounts
        @accounts ||= []
      end

      def entries
        @entries ||= []
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
