module Ledgerizer
  module Validators
    include Ledgerizer::Formatters
    include Ledgerizer::Errors

    def validate_active_record_model_name!(model_name, error_prefix)
      return true if ActiveRecord::Base.model_names.include?(model_name)

      raise_error("#{error_prefix} must be an ActiveRecord model name")
    end

    def validate_currency!(currency)
      return true if Money.available_currency?(currency)

      raise_error("invalid currency '#{currency}' given")
    end

    def validate_active_record_instance!(model_instance, error_prefix)
      return true if model_instance.is_a?(ActiveRecord::Base)

      raise_error("#{error_prefix} must be an ActiveRecord model")
    end

    def validate_money!(value)
      return true if value.is_a?(Money)

      raise_error("invalid money")
    end

    def validate_positive_money!(value)
      validate_money!(value)
      return true if value.positive?

      raise_error("value needs to be greater than 0")
    end

    def validate_date!(value)
      value.to_date
      true
    rescue ArgumentError
      raise_error("invalid date given")
    end
  end
end
