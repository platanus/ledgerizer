module Ledgerizer
  class Entry < ApplicationRecord
    belongs_to :tenant, polymorphic: true
    belongs_to :document, polymorphic: true

    validates :code, :entry_date, presence: true
  end
end
