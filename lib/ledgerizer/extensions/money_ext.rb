module Ledgerizer
  module MoneyExt
    extend ActiveSupport::Concern

    class_methods do
      def available_currency?(currency)
        Money::Currency.all.map { |cur| cur.id.to_s.upcase }.include?(currency.to_s.upcase)
      end
    end
  end
end

Money.send(:include, Ledgerizer::MoneyExt)
