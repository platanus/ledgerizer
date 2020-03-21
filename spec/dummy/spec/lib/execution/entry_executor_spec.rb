require "spec_helper"

describe Ledgerizer::EntryExecutor, type: :entry_executor do
  subject(:executor) do
    described_class.new(
      config: ledgerizer_config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_date: entry_date
    )
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
    def perform
      executor.add_movement(
        movement_type: :debit,
        account_name: :account1,
        accountable: accountable_instance,
        amount: clp(1000)
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

      before do
        executor.add_movement(m1)
        executor.add_movement(m2)
      end

      context "with no persisted entry" do
        let(:creator_result) { 666 }

        let(:creator_instance) do
          instance_double("Ledgerizer::EntryCreator", execute: creator_result)
        end

        before { allow(Ledgerizer::EntryCreator).to receive(:new).and_return(creator_instance) }

        it "calls entry creator with valid params" do
          expect(perform).to eq(creator_result)

          expect(Ledgerizer::EntryCreator).to have_received(:new).with(
            entry: kind_of(Ledgerizer::Entry),
            executable_entry: kind_of(Ledgerizer::Execution::Entry)
          ).once
        end
      end

      context "with persisted entry" do
        let(:editor_result) { 999 }

        let(:editor_instance) do
          instance_double("Ledgerizer::EntryEditr", execute: editor_result)
        end

        before do
          allow(tenant_instance).to receive(:find_or_init_entry_from_executable).and_return(
            create(:ledgerizer_entry)
          )
          allow(Ledgerizer::EntryEditor).to receive(:new).and_return(editor_instance)
        end

        it "calls entry creator with valid params" do
          expect(perform).to eq(editor_result)

          expect(Ledgerizer::EntryEditor).to have_received(:new).with(
            entry: kind_of(Ledgerizer::Entry),
            executable_entry: kind_of(Ledgerizer::Execution::Entry)
          ).once
        end
      end
    end
  end
end
