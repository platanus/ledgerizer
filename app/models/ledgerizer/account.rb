module Ledgerizer
  class Account < ApplicationRecord
    extend Enumerize

    belongs_to :tenant, polymorphic: true

    enumerize :account_type,
      in: Ledgerizer::Definition::Account::TYPES,
      predicates: { prefix: true }

    validates :name, :currency, :account_type, presence: true
    validates :currency, currency: true
  end
end
