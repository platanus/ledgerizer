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
        entry_date: executable_entry.entry_date
      )
    end

    def find_or_create_account_from_executable_movement!(movement)
      accounts.find_or_create_by!(
        tenant: self,
        accountable: movement.accountable,
        name: movement.account_name,
        currency: format_to_upcase(movement.base_currency),
        account_type: movement.account_type
      )
    end
  end
end
