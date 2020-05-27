module LedgerizableEntity
  extend ActiveSupport::Concern

  included do
    include LedgerizableEntity
    include Ledgerizer::Errors

    def to_type_attr
      return if id.blank?

      self.class.to_s
    end

    def to_id_attr
      raise_error("#{self} must implement id method") unless respond_to?(:id)

      id
    end
  end
end
