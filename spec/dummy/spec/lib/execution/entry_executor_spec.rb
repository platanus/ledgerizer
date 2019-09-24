require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
  subject(:executor) do
    described_class.new(
      config: config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code_param,
      entry_date: entry_date
    )
  end

  let(:config) { LedgerizerTest.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :entry1 }
  let(:entry_code_param) { entry_code }
  let(:entry_date) { "1984-06-04" }

  let_test_class do
    include Ledgerizer::Definition::Dsl

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

  describe "#initialize" do
    context "with non AR tenant" do
      let(:tenant_instance) { LedgerizerTest.new }

      it { expect { executor }.to raise_error("tenant must be an ActiveRecord model") }
    end

    context "with invalid AR tenant" do
      let(:tenant_instance) { create(:user) }

      it { expect { executor }.to raise_error("can't find tenant for given User model") }
    end

    context "when entry code is not in tenant" do
      let(:entry_code_param) { :entry666 }

      it { expect { executor }.to raise_error("invalid entry code entry666 for given tenant") }
    end
  end

  describe "#add_movement" do
    let(:movement_type) { :debit }
    let(:account_name) { :account1 }
    let(:accountable_instance) { create(:user) }
    let(:amount) { clp(1000) }

    def perform
      executor.add_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    it { expect(perform).to be_a(Ledgerizer::Execution::Movement) }
    it { expect { perform }.to change { executor.movements.count }.from(0).to(1) }
  end

  describe "#execute" do
    def perform
      executor.execute
    end

    it { expect { perform }.to raise_error("can't execute entry without movements") }

    context "when balance sum is not zero" do
      before do
        executor.add_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: create(:user),
          amount: clp(10)
        )

        executor.add_movement(
          movement_type: :credit,
          account_name: :account2,
          accountable: create(:user),
          amount: clp(7)
        )
      end

      it { expect { perform }.to raise_error("trial balance must be zero") }
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
        executor.add_movement(m1)
        executor.add_movement(m2)
        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(m1) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(m2) }
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
        executor.add_movement(m1)
        executor.add_movement(m2)
        executor.add_movement(m3)
        perform
      end

      it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(m1) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(m2) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(expected_line3) }
    end
  end
end
