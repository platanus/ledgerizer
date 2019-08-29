module Ledgerizer
  class Line < ApplicationRecord
    belongs_to :tenant, polymorphic: true
    belongs_to :document, polymorphic: true
    belongs_to :account
    belongs_to :entry

    monetize :amount_cents

    validates :entry_code, :entry_date, presence: true
  end
end
