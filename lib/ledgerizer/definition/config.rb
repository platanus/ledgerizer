module Ledgerizer
  module Definition
    class Config
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      def add_tenant(model_class_name:, currency: nil)
        tenant = Ledgerizer::Definition::Tenant.new(
          model_name: model_class_name,
          currency: currency
        )
        validate_unique_tenant!(tenant.model_class_name)
        tenants << tenant
        tenant
      end

      def find_tenant(value)
        tenants.find { |tenant| tenant.model_class_name == infer_model_class_name(value) }
      end

      private

      def tenants
        @tenants ||= []
      end

      def infer_model_class_name(value)
        return format_model_to_sym(value) if value.is_a?(ActiveRecord::Base)

        value
      end

      def validate_unique_tenant!(model_class_name)
        if find_tenant(model_class_name)
          raise Ledgerizer::ConfigError.new('the tenant already exists')
        end
      end
    end
  end
end
