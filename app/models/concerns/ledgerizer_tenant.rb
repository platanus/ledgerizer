module LedgerizerTenant
  extend ActiveSupport::Concern

  included do
    include LedgerizableEntity
    include LedgerizerLinesRelated
    include Ledgerizer::Formatters

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
        tenant_id: to_id_attr,
        tenant_type: to_type_attr
      }
    end

    def currency
      Ledgerizer.definition.get_tenant_currency(self)
    end

    def forbidden_line_filters
      [
        :tenant, :tenants
      ]
    end

    def account_balance(account_name, currency)
      sum = accounts.where(name: account_name, currency: format_to_upcase(currency))
                    .sum(:balance_cents)
      Money.new(sum, currency)
    end

    def account_type_balance(account_type, currency)
      sum = accounts.where(account_type: account_type, currency: format_to_upcase(currency))
                    .sum(:balance_cents)
      Money.new(sum, currency)
    end
  end
end
