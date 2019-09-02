require_rel './formatters'

module Ledgerizer
  module Validators
    include Ledgerizer::Formatters

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

    def validate_tenant_entry!(tenant, entry_code, document)
      tenant_definition = Ledgerizer.definition.find_tenant(tenant)
      entry_definition = tenant_definition.find_entry(entry_code)

      if !entry_definition
        raise_validation_error("invalid entry code #{entry_code} for given tenant")
      end

      if format_model_to_sym(document) != entry_definition.document
        raise_validation_error("invalid document #{document.class} for given #{entry_code} entry")
      end

      true
    end

    def validate_entry_account!(tenant, entry_code, account_type, account_name, accountable)
      tenant_definition = Ledgerizer.definition.find_tenant(tenant)
      entry_definition = tenant_definition.find_entry(entry_code)
      entry_account = entry_definition.send("find_#{account_type}", account_name, accountable)

      if !entry_account
        raise_validation_error(
          "invalid entry account #{account_name} with accountable " +
            "#{accountable.class} for given #{entry_code} entry in #{account_type.to_s.pluralize}"
        )
      end

      true
    end

    def validate_date!(value)
      value.to_date
      true
    rescue ArgumentError
      raise_validation_error("invalid date given")
    end

    def raise_validation_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
