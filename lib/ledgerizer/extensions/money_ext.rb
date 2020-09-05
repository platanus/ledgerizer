module Ledgerizer
  module MoneyExt
    extend ActiveSupport::Concern

    included do
      def convert_to(conversion_amount)
        variable_exchange = Money::Bank::VariableExchange.new
        variable_exchange.add_rate(
          currency.to_s,
          conversion_amount.currency.to_s,
          conversion_amount.to_f
        )
        variable_exchange.exchange_with(self, conversion_amount.currency.to_s)
      end
    end

    class_methods do
      def available_currency?(currency)
        Money::Currency.all.map { |cur| cur.id.to_s.upcase }.include?(currency.to_s.upcase)
      end
    end
  end
end

Money.include Ledgerizer::MoneyExt
