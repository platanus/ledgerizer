module LedgerizerDocument
  extend ActiveSupport::Concern

  included do
    include LedgerizableEntity

    def entries
      Ledgerizer::Entry.where(document_id: to_id_attr, document_type: to_type_attr)
    end

    def lines
      Ledgerizer::Line.where(entry_id: entries.select(:id)).sorted
    end
  end
end
