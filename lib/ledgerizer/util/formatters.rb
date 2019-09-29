module Ledgerizer
  module Formatters
    def format_to_symbol_identifier(value)
      value.to_s.tableize.singularize.to_sym
    end

    def format_to_upcase(value)
      value.to_s.upcase
    end

    def format_currency(currency, strategy: :symbol, use_default: true)
      formatted_currency = case strategy
                           when :symbol
                             format_to_symbol_identifier(currency)
                           else
                             format_to_upcase(currency)
                           end

      return :usd if use_default && formatted_currency.blank?

      formatted_currency
    end

    def format_model_to_sym(value)
      value.model_name.singular.to_sym
    end
  end
end
