module Ledgerizer
  module Definition
    class Account
      include Ledgerizer::Formatters
      include Ledgerizer::Validators

      attr_reader :name, :type, :contra

      DEBIT_TYPES = %i{asset expense}
      CREDIT_TYPES = %i{liability income equity}
      TYPES = CREDIT_TYPES + DEBIT_TYPES

      def initialize(name, type, contra = false)
        validate_not_blank!(name, "account name is mandatory")
        validate_not_blank!(type, "account type is mandatory")
        validate_account_type!(type)
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
    end
  end
end
