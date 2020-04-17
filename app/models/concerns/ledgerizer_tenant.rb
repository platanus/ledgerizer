module LedgerizerTenant
  extend ActiveSupport::Concern

  included do
    include LedgerizerLinesRelated
    include Ledgerizer::Formatters

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

    def create_entry!(executable_entry)
      entries.create!(
        code: executable_entry.code,
        document: executable_entry.document,
        entry_time: executable_entry.entry_time
      )
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
