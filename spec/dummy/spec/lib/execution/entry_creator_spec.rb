require "spec_helper"

describe Ledgerizer::EntryCreator, type: :entry_executor do
  subject(:creator) do
    described_class.new(
      entry: entry,
      executable_entry: executable_entry
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

  describe "#execute" do
    def perform
      creator.execute
    end

    context "with persisted entry" do
      before { entry.save! }

      it { expect { perform }.to raise_error(/EntryCreator with persisted entry/) }
    end

    context "with valid movements" do
      let(:expected_entry) do
        {
          entry_code: entry_code,
          entry_date: entry_date,
          document: document_instance
        }
      end

      let(:expected_m1) do
        {
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        }
      end

      let(:expected_m2) do
        {
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(10)
        }
      end

      before do
        executable_entry.add_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        )

        executable_entry.add_movement(
          movement_type: :credit,
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(10)
        )

        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
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

      let(:expected_m1) do
        {
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        }
      end

      let(:expected_m2) do
        {
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(7)
        }
      end

      let(:expected_m3) do
        {
          account_name: :account3,
          accountable: accountable_instance,
          amount: -clp(3)
        }
      end

      before do
        executable_entry.add_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        )

        executable_entry.add_movement(
          movement_type: :credit,
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(7)
        )

        executable_entry.add_movement(
          movement_type: :credit,
          account_name: :account3,
          accountable: accountable_instance,
          amount: clp(3)
        )

        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m3) }
    end
  end
end
