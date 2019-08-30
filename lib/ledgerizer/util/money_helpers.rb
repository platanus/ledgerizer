module Ledgerizer
  module MoneyHelpers
    def available_currency?(currency)
      Money::Currency.all.map { |cur| cur.id.to_s.upcase }.include?(currency.to_s.upcase)
    end
  end
end