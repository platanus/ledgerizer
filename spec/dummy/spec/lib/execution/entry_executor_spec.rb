require "spec_helper"

describe Ledgerizer::EntryExecutor do
  let(:tenant_class) { :portfolio }
  let(:tenant_instance) { create(tenant_class) }
  let(:document_instance) { create(:deposit) }
  let(:accountable_instance) { create(:user) }
  let(:entry_code) { :entry1 }
  let(:entry_date) { "1984-06-04" }
  let(:ledgerizer_config) { LedgerizerTestDefinition.definition }

  let(:executor) do
    described_class.new(
      config: ledgerizer_config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_date: entry_date
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

  describe "#add_new_movement" do
    def perform
      executor.add_new_movement(
        movement_type: :debit,
        account_name: :account1,
        accountable: accountable_instance,
        amount: clp(1000)
      )
    end

    it { expect(perform).to be_a(Ledgerizer::Execution::Movement) }
    it { expect { perform }.to change { executor.new_movements.count }.from(0).to(1) }
  end

  describe "#execute" do
    def perform
      executor.execute
    end

    def perform_adjustment
      another_executor.execute
    end

    it { expect { perform }.to raise_error("can't execute entry without movements") }

    context "when balance sum is not zero" do
      before do
        executor.add_new_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: create(:user),
          amount: clp(10)
        )

        executor.add_new_movement(
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
        executor.add_new_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        )

        executor.add_new_movement(
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
        executor.add_new_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        )

        executor.add_new_movement(
          movement_type: :credit,
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(7)
        )

        executor.add_new_movement(
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

    context "with adjustments" do
      let(:another_executor) do
        described_class.new(
          config: ledgerizer_config,
          tenant: tenant_instance,
          document: document_instance,
          entry_code: entry_code,
          entry_date: adjustment_entry_date
        )
      end

      let(:adjustment_entry_date) { "1984-06-05" }

      let(:expected_new_entry) do
        {
          entry_code: entry_code,
          entry_date: adjustment_entry_date,
          document: document_instance
        }
      end

      let(:expected_old_entry) do
        {
          entry_code: entry_code,
          entry_date: entry_date,
          document: document_instance
        }
      end

      let(:expected_old_m1) do
        {
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        }
      end

      let(:expected_old_m2) do
        {
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(10)
        }
      end

      before do
        executor.add_new_movement(
          movement_type: :debit,
          account_name: :account1,
          accountable: accountable_instance,
          amount: clp(10)
        )

        executor.add_new_movement(
          movement_type: :credit,
          account_name: :account2,
          accountable: accountable_instance,
          amount: clp(10)
        )

        perform
      end

      context "with same movements" do
        before do
          another_executor.add_new_movement(
            movement_type: :debit,
            account_name: :account1,
            accountable: accountable_instance,
            amount: clp(10)
          )

          another_executor.add_new_movement(
            movement_type: :credit,
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(10)
          )

          perform_adjustment
        end

        it { expect(tenant_instance.entries.count).to eq(1) }
        it { expect(tenant_instance.lines.count).to eq(2) }
        it { expect(tenant_instance).to have_ledger_entry(expected_old_entry) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_old_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_old_m2) }
      end

      context "when old entry date is greater than adjustment date" do
        let(:adjustment_entry_date) { "1984-06-03" }

        before do
          another_executor.add_new_movement(
            movement_type: :debit,
            account_name: :account1,
            accountable: accountable_instance,
            amount: clp(11)
          )

          another_executor.add_new_movement(
            movement_type: :credit,
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(11)
          )
        end

        it { expect { perform_adjustment }.to raise_error(/than old entry date \(1984-06-04\)/) }
      end

      context "with new movements increasing old amounts" do
        let(:expected_new_m1) do
          {
            account_name: :account1,
            accountable: accountable_instance,
            amount: clp(5)
          }
        end

        let(:expected_new_m2) do
          {
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(5)
          }
        end

        before do
          another_executor.add_new_movement(
            movement_type: :debit,
            account_name: :account1,
            accountable: accountable_instance,
            amount: clp(15)
          )

          another_executor.add_new_movement(
            movement_type: :credit,
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(15)
          )

          perform_adjustment
        end

        it { expect(tenant_instance.entries.count).to eq(2) }
        it { expect(tenant_instance.lines.count).to eq(4) }
        it { expect(tenant_instance).to have_ledger_entry(expected_old_entry) }
        it { expect(tenant_instance).to have_ledger_entry(expected_new_entry) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m1) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m2) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m2) }
      end

      context "with new movements decreasing old amounts" do
        let(:expected_new_m1) do
          {
            account_name: :account1,
            accountable: accountable_instance,
            amount: -clp(5)
          }
        end

        let(:expected_new_m2) do
          {
            account_name: :account2,
            accountable: accountable_instance,
            amount: -clp(5)
          }
        end

        before do
          another_executor.add_new_movement(
            movement_type: :debit,
            account_name: :account1,
            accountable: accountable_instance,
            amount: clp(5)
          )

          another_executor.add_new_movement(
            movement_type: :credit,
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(5)
          )

          perform_adjustment
        end

        it { expect(tenant_instance.entries.count).to eq(2) }
        it { expect(tenant_instance.lines.count).to eq(4) }
        it { expect(tenant_instance).to have_ledger_entry(expected_old_entry) }
        it { expect(tenant_instance).to have_ledger_entry(expected_new_entry) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m1) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m2) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m2) }
      end

      context "with new movements with different accontable" do
        let(:another_accountable) { create(:user) }

        let(:expected_new_m1) do
          {
            account_name: :account1,
            accountable: accountable_instance,
            amount: -clp(10)
          }
        end

        let(:expected_new_m2) do
          {
            account_name: :account1,
            accountable: another_accountable,
            amount: clp(10)
          }
        end

        before do
          another_executor.add_new_movement(
            movement_type: :debit,
            account_name: :account1,
            accountable: another_accountable,
            amount: clp(10)
          )

          another_executor.add_new_movement(
            movement_type: :credit,
            account_name: :account2,
            accountable: accountable_instance,
            amount: clp(10)
          )

          perform_adjustment
        end

        it { expect(tenant_instance.entries.count).to eq(2) }
        it { expect(tenant_instance.lines.count).to eq(4) }
        it { expect(tenant_instance).to have_ledger_entry(expected_old_entry) }
        it { expect(tenant_instance).to have_ledger_entry(expected_new_entry) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m1) }
        it { expect(tenant_instance.entries.first).to have_ledger_line(expected_old_m2) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_new_m2) }
      end
    end
  end
end
