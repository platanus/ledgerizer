module Ledgerizer
  module Formatters
    def format_to_symbol_identifier(value)
      return if value.blank?

      value.to_s.underscore.to_sym
    end

    def format_to_upcase(value)
      return if value.blank?

      value.to_s.upcase
    end

    def format_currency(currency, strategy: :symbol, use_default: true)
      formatted_currency = format_currency_by_strategy(currency, strategy)

      if use_default && formatted_currency.blank?
        default_currency = MoneyRails.default_currency.to_s
        formatted_currency = format_currency_by_strategy(default_currency, strategy)
      end

      formatted_currency
    end

    def format_ledgerizer_instance_to_sym(value)
      return value.model_name.i18n_key if value.is_a?(ActiveRecord::Base)

      format_to_symbol_identifier(value.class)
    end

    def format_string_to_class(value)
      value.to_s.camelize.constantize
    rescue NameError
      nil
    end

    def format_currency_by_strategy(currency, strategy)
      case strategy
      when :symbol
        format_to_symbol_identifier(currency)
      else
        format_to_upcase(currency)
      end
    end
  end
end
