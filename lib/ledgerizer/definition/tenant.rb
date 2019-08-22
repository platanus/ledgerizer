module Ledgerizer
  module Definition
    class Tenant
      attr_writer :currency
      attr_reader :model_class

      def initialize(model_class)
        @model_class = model_class
      end

      def currency
        @currency || :usd
      end
    end
  end
end
