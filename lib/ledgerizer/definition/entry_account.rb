module Ledgerizer
  module Definition
    class EntryAccount
      include Ledgerizer::Formatters

      attr_reader :account, :accountable

      delegate :name, to: :account, prefix: true

      def initialize(account, accountable)
        @account = account
        @accountable = infer_active_record_class_name!("entry's accountable", accountable)
      end
    end
  end
end
