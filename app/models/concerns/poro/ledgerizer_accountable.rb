module PORO::LedgerizerAccountable
  extend ActiveSupport::Concern

  included do
    include PORO::Entity

    def accounts
      Ledgerizer::Account.where(accountable_id: id, accountable_type: self.class.to_s)
    end

    def lines
      Ledgerizer::Line.where(account_id: accounts.select(:id)).sorted
    end
  end
end
