module Ledgerizer
  module Definition
    class Config
      def add_tenant(model_class, currency = nil)
        tenant = Ledgerizer::Definition::Tenant.new(model_class, currency)
        validate_unique_tenant!(tenant.model_class)
        @tenants << tenant
        tenant
      end

      def find_tenant(model_class)
        tenants.find { |tenant| tenant.model_class == model_class }
      end

      private

      def tenants
        @tenants ||= []
      end

      def validate_unique_tenant!(model_class)
        if find_tenant(model_class)
          raise Ledgerizer::ConfigError.new('the tenant already exists')
        end
      end
    end
  end
end
