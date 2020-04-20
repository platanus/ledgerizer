module PORO::LedgerizerDocument
  extend ActiveSupport::Concern

  included do
    include PORO::Entity

    def entries
      Ledgerizer::Entry.where(document_id: id, document_type: self.class.to_s)
    end

    def lines
      Ledgerizer::Line.where(entry_id: entries.select(:id)).sorted
    end
  end
end
