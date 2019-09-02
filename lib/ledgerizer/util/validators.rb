module Ledgerizer
  module Validators
    def validate_active_record_model_name!(model_class_name, error_prefix)
      return true if ActiveRecord::Base.model_names.include?(model_class_name)

      raise_validation_error("#{error_prefix} must be an ActiveRecord model name")
    end

    def validate_currency!(currency)
      return true if Money.available_currency?(currency)

      raise_validation_error("invalid currency '#{currency}' given")
    end

    def validate_tenant_instance!(model_class_name)
      return true if Ledgerizer.definition.find_tenant(model_class_name)

      raise_validation_error("can't find tenant for given '#{model_class_name}' model name")
    end

    def raise_validation_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
