require_rel './validators'

module Ledgerizer
  module Formatters
    include Ledgerizer::Validators

    def format_to_symbol_identifier(value)
      value.to_s.tableize.singularize.to_sym
    end

    def format_to_upcase
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
  end
end
