module Ledgerizer
  module Definition
    class Account
      attr_reader :name, :type

      def initialize(name, type)
        @name = name
        @type = type
      end
    end
  end
end
