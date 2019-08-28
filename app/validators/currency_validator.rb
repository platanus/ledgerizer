class CurrencyValidator < ActiveModel::EachValidator
  include Ledgerizer::MoneyHelpers

  def validate_each(record, attribute, value)
    if !available_currency?(value)
      record.errors[attribute] << (options[:message] || "is invalid")
    end
  end
end
