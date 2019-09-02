require_rel './validators'

module Ledgerizer
  module Formatters
    include Ledgerizer::Validators

    def infer_active_record_class_name!(error_prefix, model_name)
      klass_name = model_name.to_s.tableize.singularize.to_sym
      validate_active_record_model_name!(klass_name, error_prefix)
      klass_name
    end

    def format_currency!(currency)
      formatted_currency = currency.to_s.downcase.to_sym
      return :usd if formatted_currency.blank?

      validate_currency!(formatted_currency)
      formatted_currency
    end
  end
end
