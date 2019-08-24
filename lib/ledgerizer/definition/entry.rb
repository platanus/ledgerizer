module Ledgerizer
  module Definition
    class Entry
      include Ledgerizer::Formatters

      attr_reader :code, :document

      def initialize(code, document)
        @code = code.to_s.to_sym
        @document = infer_active_record_class!("entry's document", document)
      end

      def add_debit(account, accountable)
        add_entry_account(debits, account, accountable)
      end

      def add_credit(account, accountable)
        add_entry_account(credits, account, accountable)
      end

      def find_entry_account(collection, account_name, accountable)
        collection.find do |entry_account|
          entry_account.account_name == account_name &&
            entry_account.accountable == accountable
        end
      end

      def debits
        @debits ||= []
      end

      def credits
        @credits ||= []
      end

      private

      def add_entry_account(collection, account, accountable)
        ar_accountable = infer_active_record_class!('accountable', accountable)
        validate_unique_account!(collection, account.name, ar_accountable)

        Ledgerizer::Definition::EntryAccount.new(account, ar_accountable).tap do |entry_account|
          collection << entry_account
        end
      end

      def validate_unique_account!(collection, account_name, accountable)
        if find_entry_account(collection, account_name, accountable)
          raise Ledgerizer::ConfigError.new(
            "entry account #{account_name} with accountable #{accountable} already exists in tenant"
          )
        end
      end
    end
  end
end
