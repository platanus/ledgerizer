module LedgerizerDocument
  extend ActiveSupport::Concern

  included do
    has_many :entries,
             as: :document,
             class_name: "Ledgerizer::Entry",
             dependent: :destroy

    has_many :lines, through: :entries, class_name: "Ledgerizer::Line"
  end
end
