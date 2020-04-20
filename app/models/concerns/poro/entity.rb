module PORO::Entity
  extend ActiveSupport::Concern

  included do
    if !method_defined?(:id)
      define_method(:id) do
        nil
      end
    end

    def _read_attribute(_arg); end

    def marked_for_destruction?; end

    def destroyed?; end

    def new_record?; end
  end

  class_methods do
    def primary_key
      :id
    end

    def polymorphic_name
      to_s
    end
  end
end
