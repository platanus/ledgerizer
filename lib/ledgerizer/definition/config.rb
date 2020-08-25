module Ledgerizer
  module Definition
    class Config
      include Ledgerizer::Validators
      include Ledgerizer::Formatters
      include Ledgerizer::Common

      attr_writer :running_inside_transactional_fixtures

      def running_inside_transactional_fixtures
        @running_inside_transactional_fixtures || false
      end

      def add_tenant(model_name:, currency: nil)
        tenant = Ledgerizer::Definition::Tenant.new(
          model_name: model_name,
          currency: currency
        )
        validate_unique_tenant!(tenant.model_name)
        tenants << tenant
        tenant
      end

      def find_tenant(value)
        tenants.find { |tenant| tenant.model_name == infer_ledgerized_class_name(value) }
      end

      def get_tenant_currency(tenant)
        config = find_tenant(tenant)
        raise_config_error("tenant's config does not exist") unless config
        config.currency
      end

      private

      def tenants
        @tenants ||= []
      end

      def validate_unique_tenant!(model_name)
        raise_config_error('the tenant already exists') if find_tenant(model_name)
      end
    end
  end
end
