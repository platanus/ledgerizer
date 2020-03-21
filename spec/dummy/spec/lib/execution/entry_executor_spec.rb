require "spec_helper"

describe Ledgerizer::EntryExecutor do
  subject(:executor) do
    described_class.new(
      config: config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_date: entry_date
    )
  end

  let(:config) { LedgerizerTestDefinition.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :entry1 }
  let(:entry_date) { "1984-06-04" }

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1)
      liability(:account2)

      entry(:entry1, document: :user) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
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
      let(:entry_code) { :entry666 }

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

      let(:creator_result) { 666 }

      let(:creator_instance) do
        instance_double("Ledgerizer::EntryCreator", execute: creator_result)
      end

      before do
        executor.add_movement(m1)
        executor.add_movement(m2)
        allow(Ledgerizer::EntryCreator).to receive(:new).and_return(creator_instance)
      end

      it "calls entry creator with valid params" do
        expect(perform).to eq(creator_result)

        expect(Ledgerizer::EntryCreator).to have_received(:new).with(
          entry: kind_of(Ledgerizer::Entry),
          executable_entry: kind_of(Ledgerizer::Execution::Entry)
        )
      end
    end
  end
end
