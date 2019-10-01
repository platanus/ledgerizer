module LedgerizerAccountable
  extend ActiveSupport::Concern

  included do
    has_many :accounts,
             as: :accountable,
             class_name: "Ledgerizer::Account",
             dependent: :destroy

    has_many :lines, through: :accounts, class_name: "Ledgerizer::Line"
  end
end
