module Ledgerizer
  module Definition
    class Account
      include Ledgerizer::Formatters
      include Ledgerizer::Validators

      attr_reader :name, :type, :contra, :currency, :mirror_currency

      DEBIT_TYPES = %i{asset expense}
      CREDIT_TYPES = %i{liability income equity}
      TYPES = CREDIT_TYPES + DEBIT_TYPES

      def initialize(name:, type:, currency:, mirror_currency: nil, contra: false)
        validate_account_type!(type)
        @name = format_to_symbol_identifier(name)
        @type = format_to_symbol_identifier(type)
        @currency = format_currency(currency)
        @mirror_currency = format_currency(mirror_currency, use_default: false)
        @contra = !!contra
      end

      def credit?
        CREDIT_TYPES.include?(type)
      end

      def debit?
        DEBIT_TYPES.include?(type)
      end

      private

      def validate_account_type!(type)
        if !TYPES.include?(type.to_sym)
          raise_config_error("type must be one of these: #{TYPES.join(', ')}")
        end
      end
    end
  end
end
