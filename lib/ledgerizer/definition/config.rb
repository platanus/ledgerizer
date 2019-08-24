module Ledgerizer
  module Definition
    class Config
      def add_tenant(model_class_name, currency = nil)
        tenant = Ledgerizer::Definition::Tenant.new(model_class_name, currency)
        validate_unique_tenant!(tenant.model_class_name)
        @tenants << tenant
        tenant
      end

      def find_tenant(model_class_name)
        tenants.find { |tenant| tenant.model_class_name == model_class_name }
      end

      private

      def tenants
        @tenants ||= []
      end

      def validate_unique_tenant!(model_class_name)
        if find_tenant(model_class_name)
          raise Ledgerizer::ConfigError.new('the tenant already exists')
        end
      end
    end
  end
end
