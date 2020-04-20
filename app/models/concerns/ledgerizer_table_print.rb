module LedgerizerTablePrint
  extend ActiveSupport::Concern

  included do
    def to_table
      self.class.where(id: id).to_table
    end
  end

  class_methods do
    def to_table
      tp(all, table_print_attributes)
    end

    def table_print_attributes
      attrs = column_names.reverse.inject([]) do |result, attribute|
        load_attribute(result, attribute)
      end

      amount = attrs.delete("amount_cents")
      attrs << "amount.format" if amount

      amount = attrs.delete("balance_cents")
      attrs << "balance.format" if amount

      ["id"] + attrs
    end

    def load_attribute(result, attribute)
      if attribute.ends_with?("_currency") || %w{created_at updated_at id}.include?(attribute)
        nil
      else
        result << attribute
      end

      result
    end
  end
end
