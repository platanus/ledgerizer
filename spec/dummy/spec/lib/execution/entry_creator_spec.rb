require "spec_helper"

describe Ledgerizer::EntryCreator do
  subject(:creator) do
    described_class.new(
      entry: entry,
      executable_entry: executable_entry
    )
  end

  let(:tenant_class) { :portfolio }
  let(:tenant_instance) { create(tenant_class) }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :entry1 }
  let(:entry_date) { "1984-06-04" }

  let(:config) { LedgerizerTestDefinition.definition }

  let(:entry_definition) do
    config.find_tenant(tenant_class).find_entry(entry_code)
  end

  let(:executable_entry) do
    build(
      :executable_entry,
      entry_definition: entry_definition,
      document: document_instance,
      entry_date: entry_date
    )
  end

  let(:entry) do
    build(
      :ledgerizer_entry,
      tenant: tenant_instance,
      document: document_instance,
      code: entry_code,
      entry_date: entry_date
    )
  end

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1)
      liability(:account2)
      asset(:account3)

      entry(:entry1, document: :user) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
      end

      entry(:entry2, document: :user) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
        credit(account: :account3, accountable: :user)
      end
    end
  end

  describe "#execute" do
    def perform
      creator.execute
    end

    context "with valid movements" do
      let(:expected_entry) do
        {
          entry_code: entry_code,
          entry_date: entry_date,
          document: document_instance
        }
      end

      let(:m1) do
        {
          movement_type: :debit,
          account_name: :account1,
          accountable: create(:user),
          amount: clp(10)
        }
      end

      let(:m2) do
        {
          movement_type: :credit,
          account_name: :account2,
          accountable: create(:user),
          amount: clp(10)
        }
      end

      before do
        executable_entry.add_movement(m1)
        executable_entry.add_movement(m2)
        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(m1) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(m2) }
    end

    context "with multiple movements" do
      let(:entry_code) { :entry2 }

      let(:expected_entry) do
        {
          entry_code: entry_code,
          entry_date: entry_date,
          document: document_instance
        }
      end

      let(:m1) do
        {
          movement_type: :debit,
          account_name: :account1,
          accountable: create(:user),
          amount: clp(10)
        }
      end

      let(:m2) do
        {
          movement_type: :credit,
          account_name: :account2,
          accountable: create(:user),
          amount: clp(7)
        }
      end

      let(:m3) do
        {
          movement_type: :credit,
          account_name: :account3,
          accountable: create(:user),
          amount: clp(3)
        }
      end

      let(:expected_line3) do
        line = m3.dup
        line[:amount] = -line[:amount]
        line
      end

      before do
        executable_entry.add_movement(m1)
        executable_entry.add_movement(m2)
        executable_entry.add_movement(m3)
        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(m1) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(m2) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_line3) }
    end
  end
end
