module Ledgerizer
  module Validators
    include Ledgerizer::Formatters
    include Ledgerizer::Errors

    def validate_ledgerized_class_name!(value, error_prefix, ledgerizer_mixin)
      klass = format_string_to_class(value)

      if klass.blank?
        raise_error("#{error_prefix} must be a snake_case representation of a Ruby class")
      end

      return true if klass.ancestors.include?(ledgerizer_mixin)

      raise_error("#{error_prefix} must include #{ledgerizer_mixin}")
    end

    def validate_currency!(currency)
      return true if Money.available_currency?(currency)

      raise_error("invalid currency '#{currency}' given")
    end

    def validate_ledgerized_instance!(value, error_prefix, ledgerizer_mixin)
      return true if value.class.ancestors.include?(ledgerizer_mixin)

      raise_error("#{error_prefix} must be an instance of a class including #{ledgerizer_mixin}")
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

    def validate_datetime!(value)
      value.to_datetime
      true
    rescue ArgumentError
      raise_error("invalid datetime given")
    end
  end
end
