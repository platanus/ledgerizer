module PORO::LedgerizerTenant
  extend ActiveSupport::Concern

  included do
    include PORO::Entity

    def accounts
      Ledgerizer::Account.where(tenant_where_params)
    end

    def entries
      Ledgerizer::Entry.where(tenant_where_params)
    end

    def lines
      Ledgerizer::Line.where(tenant_where_params).sorted
    end

    def tenant_where_params
      {
        tenant_id: id,
        tenant_type: self.class.to_s
      }
    end
  end
end
