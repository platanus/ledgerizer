module FactoryBot
  class SyntaxRunner
    include MoneyHelpers

    def set_polymorphic_relation(instance, attribute, polymorphic_instance)
      return if polymorphic_instance.blank?

      instance.update_columns(
        "#{attribute}_id" => polymorphic_instance.id,
        "#{attribute}_type" => polymorphic_instance.class.to_s
      )
    end

    def set_denormalized_attribute(instance, attribute, value)
      return if value.blank?

      instance.update_column(attribute, value)
    end
  end
end
