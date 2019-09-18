module Ledgerizer
  module Formatters
    def infer_active_record_class_name!(error_prefix, model_name)
      klass_name = model_name.to_s.tableize.singularize.to_sym

      if !model_names.include?(klass_name)
        raise_formatter_error("#{error_prefix} must be an ActiveRecord model name")
      end

      klass_name
    end

    def format_currency!(currency)
      formatted_currency = currency.to_s.downcase.to_sym
      return :usd if formatted_currency.blank?
      return formatted_currency if available_currency?(formatted_currency)

      raise_formatter_error("invalid currency '#{currency}' given")
    end

    def available_currency?(currency)
      Money::Currency.all.map(&:id).include?(currency)
    end

    def model_names
      model_files = Dir.glob(Rails.root.join("app", "models", "**", "*").to_s).select do |f|
        f.ends_with?('.rb') && !f.include?('concerns')
      end

      model_files.map { |file| file.split('/').last.split('.').first.singularize.to_sym }.sort
    end

    def raise_formatter_error(msg)
      raise Ledgerizer::Error.new(msg)
    end
  end
end
