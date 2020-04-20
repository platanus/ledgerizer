module AR::LedgerizerTenant
  extend ActiveSupport::Concern

  included do
    has_many :accounts,
             as: :tenant,
             class_name: "Ledgerizer::Account",
             dependent: :destroy

    has_many :entries,
             as: :tenant,
             class_name: "Ledgerizer::Entry",
             dependent: :destroy

    has_many :lines, -> { sorted },
             as: :tenant,
             class_name: "Ledgerizer::Line",
             dependent: :destroy
  end
end
