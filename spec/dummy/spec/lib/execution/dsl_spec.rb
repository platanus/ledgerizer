require "spec_helper"

RSpec.describe Ledgerizer::Execution::Dsl do
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

  let(:tenant) { create(:portfolio) }
  let(:document) { create(:user) }
  let(:date) { "1984-06-04".to_date }

  describe '#executor_xxx_entry' do
    context "with invalid entry" do
      def perform
        LedgerizerTestExecution.new.execute_fake_entry(
          tenant: tenant, document: document, date: date
        )
      end

      it { expect { perform }.to raise_error('invalid entry code fake for given tenant') }
    end

    context "with no movements" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, date: date
        )
      end

      it { expect { perform }.to raise_error("can't execute entry without movements") }
    end

    context "with invalid tenant" do
      let(:tenant) { create(:user) }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, date: date
        )
      end

      it { expect { perform }.to raise_error("can't find tenant for given User model") }
    end

    context "with invalid document" do
      let(:document) { create(:portfolio) }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, date: date
        )
      end

      it { expect { perform }.to raise_error("invalid document Portfolio for given entry1 entry") }
    end

    context "with invalid entry date" do
      let(:date) { 'invalid' }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, date: date
        )
      end

      it { expect { perform }.to raise_error("invalid date given") }
    end

    context "with invalid amounts" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, date: date
        ) do
          debit(account: :account1, accountable: FactoryBot.create(:user), amount: Money.new(10))
          credit(account: :account2, accountable: FactoryBot.create(:user), amount: Money.new(7))
        end
      end

      it { expect { perform }.to raise_error("trial balance must be zero") }
    end

    context "with valid movements" do
      let(:expected_entry) do
        {
          entry_code: :entry1,
          entry_date: date,
          document: document
        }
      end

      let(:debit_data) do
        {
          account: :account1,
          accountable: create(:user),
          amount: clp(1)
        }
      end

      let(:credit_data) do
        {
          account: :account2,
          accountable: create(:user),
          amount: clp(1)
        }
      end

      before do
        LedgerizerTestExecution.new(debit: debit_data, credit: credit_data).execute_entry1_entry(
          tenant: tenant, document: document, date: date
        ) do
          debit(data[:debit])
          credit(data[:credit])
        end
      end

      it { expect(tenant).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(debit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(credit_data) }
    end

    context "with multiple movements" do
      let(:expected_entry) do
        {
          entry_code: :entry2,
          entry_date: date,
          document: document
        }
      end

      let(:debit_data) do
        {
          account: :account1,
          accountable: create(:user),
          amount: clp(2)
        }
      end

      let(:credit_data1) do
        {
          account: :account2,
          accountable: create(:user),
          amount: clp(1)
        }
      end

      let(:credit_data2) do
        {
          account: :account3,
          accountable: create(:user),
          amount: clp(1)
        }
      end

      let(:expected_credit_data2) do
        line = credit_data2.dup
        line[:amount] = -line[:amount]
        line
      end

      before do
        data = { debit: debit_data, credit: [credit_data1, credit_data2] }
        LedgerizerTestExecution.new(data).execute_entry2_entry(
          tenant: tenant, document: document, date: date
        ) do
          debit(data[:debit])
          credit(data[:credit].first)
          credit(data[:credit].last)
        end
      end

      it { expect(tenant).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(debit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(credit_data1) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(expected_credit_data2) }
    end
  end
end