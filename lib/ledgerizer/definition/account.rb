module Ledgerizer
  module Definition
    class Account
      include Ledgerizer::Formatters

      attr_reader :name, :type, :contra

      DEBIT_TYPES = %i{asset expense}
      CREDIT_TYPES = %i{liability income equity}
      TYPES = CREDIT_TYPES + DEBIT_TYPES

      def initialize(name, type, contra = false)
        ensure_name!(name)
        ensure_type!(type)
        @name = format_to_symbol_identifier(name)
        @type = format_to_symbol_identifier(type)
        @contra = !!contra
      end

      def credit?
        CREDIT_TYPES.include?(type)
      end

      def debit?
        DEBIT_TYPES.include?(type)
      end

      private

      def ensure_name!(name)
        raise Ledgerizer::ConfigError.new("account name is mandatory") if name.blank?
      end

      def ensure_type!(type)
        raise Ledgerizer::ConfigError.new("account type is mandatory") if type.blank?

        if !TYPES.include?(type.to_sym)
          raise Ledgerizer::ConfigError.new("type must be one of these: #{TYPES.join(', ')}")
        end
      end
    end
  end
end
