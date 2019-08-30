module Ledgerizer
  module Definition
    class Account
      attr_reader :name, :type, :contra

      TYPES = %i{asset liability income expense equity}

      def initialize(name, type, contra = false)
        ensure_name!(name)
        ensure_type!(type)
        @name = name.to_sym
        @type = type.to_sym
        @contra = !!contra
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
