module Ledgerizer
  module Definition
    class RevaluationAccount
      include Ledgerizer::Formatters

      attr_reader :name, :accountable

      def initialize(name:, accountable: nil)
        @name = format_to_symbol_identifier(name)
        @accountable = format_to_symbol_identifier(accountable) if accountable.present?
      end
    end
  end
end
