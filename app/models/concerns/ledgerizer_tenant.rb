module LedgerizerTenant
  extend ActiveSupport::Concern

  included do
    include LedgerizerLinesRelated

    has_many :accounts,
             as: :tenant,
             class_name: "Ledgerizer::Account",
             dependent: :destroy

    has_many :entries,
             as: :tenant,
             class_name: "Ledgerizer::Entry",
             dependent: :destroy

    has_many :lines,
             as: :tenant,
             class_name: "Ledgerizer::Line",
             dependent: :destroy

    def currency
      Ledgerizer.definition.get_tenant_currency(self)
    end

    def forbidden_line_filters
      [
        :tenant, :tenants
      ]
    end
  end
end
