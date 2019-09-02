module Ledgerizer
  module Validators
    def validate_active_record_model_name!(klass_name, error_prefix)
      if !ActiveRecord::Base.model_names.include?(klass_name)
        raise_formatter_error("#{error_prefix} must be an ActiveRecord model name")
      end

      true
    end

    def validate_currency!(currency)
      if !Money.available_currency?(currency)
        raise_formatter_error("invalid currency '#{currency}' given")
      end

      true
    end

    def raise_formatter_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
