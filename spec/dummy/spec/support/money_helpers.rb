module MoneyHelpers
  extend ActiveSupport::Concern

  included do
    def clp(value)
      Money.from_amount(value, :clp)
    end
  end
end
