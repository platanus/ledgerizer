module PolymorphicAttrs
  extend ActiveSupport::Concern

  included do
    include Ledgerizer::Errors
  end

  class_methods do
    def polymorphic_attr(name)
      type_method = "#{name}_type"
      id_method = "#{name}_id"
      define_polymorphic_attr_getter(name, type_method, id_method)
      define_polymorphic_attr_setter(name, type_method, id_method)
    end

    def define_polymorphic_attr_getter(name, type_method, id_method)
      define_method(name) do
        class_string = send(type_method).to_s
        id_value = send(id_method)
        return if class_string.blank?

        klass = class_string.constantize
        return klass.find_by(id: id_value) if klass.ancestors.include?(ActiveRecord::Base)

        raise_error("can't deserialize #{name}, just ActiveRecord instances")
      end
    end

    def define_polymorphic_attr_setter(name, type_method, id_method)
      define_method("#{name}=") do |value|
        raise_error("#{value} must implement id method") unless value.respond_to?(:id)
        send("#{type_method}=", value.blank? ? nil : value.class.to_s)
        send("#{id_method}=", value.id)
      end
    end
  end
end
