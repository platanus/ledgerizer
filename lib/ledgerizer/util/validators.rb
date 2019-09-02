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

    def validate_tenant_instance!(model_instance, error_prefix)
      validate_active_record_instance!(model_instance, error_prefix)
      return true if Ledgerizer.definition.find_tenant(model_instance)

      raise_validation_error("can't find tenant for given #{model_instance.model_name} model")
    end

    def validate_active_record_instance!(model_instance, error_prefix)
      return true if model_instance.is_a?(ActiveRecord::Base)

      raise_validation_error("#{error_prefix} must be an ActiveRecord model")
    end

    def validate_tenant_entry!(tenant, entry_code)
      tenant_definition = Ledgerizer.definition.find_tenant(tenant)
      return true if tenant_definition.find_entry(entry_code)

      raise_validation_error("invalid entry code #{entry_code} for given tenant")
    end

    def raise_validation_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
