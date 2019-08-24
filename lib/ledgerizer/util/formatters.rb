module Ledgerizer
  module Formatters
    def infer_active_record_class!(error_prefix, model_name)
      klass = model_name.to_s.classify.constantize
      raise_non_ar_model_error(error_prefix) unless klass.ancestors.include?(ActiveRecord::Base)
      klass
    rescue NameError
      raise_non_ar_model_error(error_prefix)
    end

    def format_currency!(currency)
      formatted_currency = currency.to_s.downcase.to_sym
      return :usd if formatted_currency.blank?
      return formatted_currency if Money::Currency.table.key?(formatted_currency)

      raise_formatter_error("invalid currency '#{currency}' given")
    end

    def raise_non_ar_model_error(error_prefix)
      raise_formatter_error("#{error_prefix} must be an ActiveRecord model name")
    end

    def raise_formatter_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
