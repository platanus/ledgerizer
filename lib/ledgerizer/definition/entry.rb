module Ledgerizer
  module Definition
    class Entry
      attr_reader :code, :document

      def initialize(code, document)
        @code = code
        @document = document
      end
    end
  end
end
