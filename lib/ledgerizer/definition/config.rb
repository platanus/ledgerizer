module Ledgerizer
  module Definition
    class Config
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

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
        tenants.find { |tenant| tenant.model_name == infer_model_name(value) }
      end

      def include_account?(account_name)
        accounts_names.include?(account_name.to_s.to_sym)
      end

      def get_tenant_currency(tenant)
        find_tenant(tenant)&.currency
      end

      private

      def tenants
        @tenants ||= []
      end

      def accounts_names
        tenants.map(&:accounts_names).flatten.uniq
      end

      def infer_model_name(value)
        return format_model_to_sym(value) if value.is_a?(ActiveRecord::Base)

        value
      end

      def validate_unique_tenant!(model_name)
        raise_config_error('the tenant already exists') if find_tenant(model_name)
      end
    end
  end
end
