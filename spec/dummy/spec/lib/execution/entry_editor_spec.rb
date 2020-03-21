require "spec_helper"

describe Ledgerizer::EntryEditor, type: :entry_executor do
  subject(:editor) do
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

  def perform
    editor.execute
  end

  it { expect { perform }.to raise_error(/Ledgerizer::EntryEditor with not persisted/) }

  context "with pair of movements saved" do
    before do
      entry.save!
      create(:ledgerizer_line, entry: entry, account: account1, amount: clp(10))
      create(:ledgerizer_line, entry: entry, account: account2, amount: clp(10))
    end

    context "with new movements with same amounts" do
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

      it { expect(tenant_instance.entries.count).to eq(1) }
      it { expect(tenant_instance.lines.count).to eq(2) }
      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
      it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
    end
  end
end
