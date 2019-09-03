module MoneyHelpers
  extend ActiveSupport::Concern

  included do
    def clp(value)
      Money.from_amount(value, :clp)
    end

    def usd(value)
      Money.from_amount(value, :usd)
    end
  end
end
