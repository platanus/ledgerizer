module ExecutorHelpers
  extend ActiveSupport::Concern

  included do
    let(:tenant_class) { :portfolio }
    let(:tenant_instance) { create(tenant_class) }
    let(:document_instance) { create(:deposit) }
    let(:accountable_instance) { create(:user) }
    let(:entry_code) { :entry1 }
    let(:entry_date) { "1984-06-04" }

    let(:ledgerizer_config) { LedgerizerTestDefinition.definition }

    let(:entry_definition) do
      ledgerizer_config.find_tenant(tenant_class).find_entry(entry_code)
    end

    let(:executable_entry) do
      build(
        :executable_entry,
        entry_definition: entry_definition,
        document: document_instance,
        entry_date: entry_date
      )
    end

    let(:account1) do
      create(
        :ledgerizer_account,
        tenant: tenant_instance,
        accountable: accountable_instance,
        name: :account1,
        account_type: :asset,
        currency: 'CLP'
      )
    end

    let(:account2) do
      create(
        :ledgerizer_account,
        tenant: tenant_instance,
        accountable: accountable_instance,
        name: :account2,
        account_type: :liability,
        currency: 'CLP'
      )
    end

    let(:account3) do
      create(
        :ledgerizer_account,
        tenant: tenant_instance,
        accountable: accountable_instance,
        name: :account3,
        account_type: :asset,
        currency: 'CLP'
      )
    end

    let_definition_class do
      tenant('portfolio', currency: :clp) do
        asset(:account1)
        liability(:account2)
        asset(:account3)

        entry(:entry1, document: :deposit) do
          debit(account: :account1, accountable: :user)
          credit(account: :account2, accountable: :user)
        end

        entry(:entry2, document: :deposit) do
          debit(account: :account1, accountable: :user)
          credit(account: :account2, accountable: :user)
          credit(account: :account3, accountable: :user)
        end
      end
    end
  end
end
