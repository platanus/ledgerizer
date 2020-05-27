module Ledgerizer
  module Common
    def ledgerized_instance?(value)
      (value.class.ancestors & [LedgerizerAccountable, LedgerizerDocument, LedgerizerTenant]).any?
    end

    def infer_ledgerized_class_name(value)
      return format_ledgerizer_instance_to_sym(value) if ledgerized_instance?(value)

      value
    end
  end
end
