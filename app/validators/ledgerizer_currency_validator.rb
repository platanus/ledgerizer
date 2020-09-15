class LedgerizerCurrencyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    if !Money.available_currency?(value)
      record.errors[attribute] << (options[:message] || "is invalid")
    end
  end
end
