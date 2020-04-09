module Ledgerizer
  module Execution
    class Account
      def initialize(tenant:, accountable:, account_type:, account_name:, currency:)
        @tenant = tenant
        @accountable = accountable
        @account_type = account_type
        @account_name = account_name
        @currency = currency
      end

      def ==(other)
        to_array == other.to_array
      end

      def eql?(other)
        self == other
      end

      def identifier
        to_array.join('::')
      end

      def to_array
        [
          tenant.class.to_s,
          tenant.id,
          accountable.class.to_s,
          accountable.id,
          account_type.to_s,
          account_name.to_s,
          currency.to_s
        ]
      end

      def to_hash
        {
          tenant: tenant,
          accountable: accountable,
          account_type: account_type,
          name: account_name,
          currency: currency
        }
      end

      def <=>(other)
        to_array <=> other.to_array
      end

      private

      attr_reader :tenant, :accountable, :account_type, :account_name, :currency
    end
  end
end
