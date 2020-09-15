module Ledgerizer
  module Execution
    class Account
      include Ledgerizer::Formatters

      attr_reader :mirror_currency

      def initialize(
        tenant_id:,
        tenant_type:,
        accountable_id:,
        accountable_type:,
        account_type:,
        account_name:,
        currency:,
        mirror_currency:
      )
        @tenant_id = tenant_id
        @tenant_type = tenant_type
        @accountable_id = accountable_id
        @accountable_type = accountable_type
        @account_type = account_type
        @account_name = account_name
        @currency = format_currency(currency, strategy: :upcase, use_default: false)
        @mirror_currency = format_currency(mirror_currency, strategy: :upcase, use_default: false)
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
          tenant_type,
          tenant_id,
          accountable_type,
          accountable_id,
          account_type,
          account_name,
          currency,
          mirror_currency
        ].map(&:to_s)
      end

      def to_hash
        {
          tenant_id: tenant_id,
          tenant_type: tenant_type,
          accountable_id: accountable_id,
          accountable_type: accountable_type,
          account_type: account_type,
          name: account_name,
          currency: currency,
          mirror_currency: mirror_currency
        }
      end

      def <=>(other)
        to_array <=> other.to_array
      end

      def balance
        params = to_hash.dup
        params[:account_name] = params.delete(:name)
        params[:account_mirror_currency] = params.delete(:mirror_currency)
        balance_currency = params.delete(:currency)
        Ledgerizer::Line.where(params).amounts_sum(balance_currency)
      end

      private

      attr_reader :account_type, :account_name, :currency
      attr_reader :accountable_id, :accountable_type
      attr_reader :tenant_id, :tenant_type
    end
  end
end
