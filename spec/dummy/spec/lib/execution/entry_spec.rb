require "spec_helper"

RSpec.describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    described_class.new(
      entry_definition: entry_definition,
      document: document_instance,
      entry_date: entry_date
    )
  end

  let(:entry_definition) do
    Ledgerizer::Definition::Entry.new(code: entry_code, document: document)
  end

  let(:document) { :user }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  it { expect(execution_entry.entry_date).to eq(entry_date.to_date) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with non AR document" do
    let(:document_instance) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error("document must be an ActiveRecord model") }
  end

  context "with invalid AR document" do
    let(:document_instance) { create(:portfolio) }

    it { expect { execution_entry }.to raise_error(/invalid document Portfolio for given deposit/) }
  end

  context "with invalid date" do
    let(:entry_date) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid date given") }
  end

  describe "#add_entry_account" do
    let(:movement_type) { :debit }
    let(:account_name) { :cash }
    let(:account_type) { :asset }
    let(:accountable_instance) { create(:user) }
    let(:accountable) { :user }
    let(:amount) { clp(1000) }
    let(:base_currency) { :clp }
    let(:contra) { false }

    let(:account) do
      Ledgerizer::Definition::Account.new(
        name: account_name,
        type: account_type,
        base_currency: base_currency,
        contra: contra
      )
    end

    def perform
      execution_entry.add_entry_account(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    context "with no definition entry account" do
      let(:error_msg) do
        'invalid entry account cash with accountable User for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with existent definition entry account" do
      before do
        entry_definition.add_entry_account(
          movement_type: movement_type,
          account: account,
          accountable: accountable
        )
      end

      it { expect { perform }.to change { execution_entry.entry_accounts.count }.from(0).to(1) }

      context "with non AR document" do
        let(:accountable_instance) { LedgerizerTest.new }

        it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
      end

      context "with invalid AR document" do
        let(:accountable_instance) { create(:portfolio) }

        it { expect { perform }.to raise_error(/accountable Portfolio for given deposit/) }
      end
    end
  end
end
