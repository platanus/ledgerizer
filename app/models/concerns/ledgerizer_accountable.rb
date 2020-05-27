module LedgerizerAccountable
  extend ActiveSupport::Concern

  included do
    include LedgerizableEntity

    def accounts
      Ledgerizer::Account.where(accountable_id: to_id_attr, accountable_type: to_type_attr)
    end

    def lines
      Ledgerizer::Line.where(account_id: accounts.select(:id)).sorted
    end
  end
end
