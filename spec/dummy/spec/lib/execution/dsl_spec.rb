require "spec_helper"

describe Ledgerizer::Execution::Dsl do
  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1, currencies: [:usd])
      liability(:account2, currencies: [:usd])
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

      entry(:entry3, document: :deposit) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2)
      end
    end
  end

  let(:tenant) { create(:portfolio) }
  let(:document) { create(:deposit) }
  let(:datetime) { "1984-06-04".to_datetime }

  describe '#executor_xxx_entry' do
    context "with invalid entry" do
      def perform
        LedgerizerTestExecution.new.execute_fake_entry(
          tenant: tenant, document: document, datetime: datetime
        )
      end

      it { expect { perform }.to raise_error('invalid entry code fake for given tenant') }
    end

    context "with no movements" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        )
      end

      it { expect { perform }.to raise_error("can't execute entry without movements") }
    end

    context "with invalid tenant" do
      let(:tenant) { create(:user) }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        )
      end

      it { expect { perform }.to raise_error(/instance of a class including LedgerizerTenant/) }
    end

    context "with invalid document" do
      let(:document) { build(:withdrawal) }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        )
      end

      it { expect { perform }.to raise_error("invalid document Withdrawal for given entry1 entry") }
    end

    context "with invalid entry date" do
      let(:datetime) { 'invalid' }

      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        )
      end

      it { expect { perform }.to raise_error("invalid datetime given") }
    end

    context "with not matching amounts" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        ) do
          debit(account: :account1, accountable: FactoryBot.create(:user), amount: Money.new(10))
          credit(account: :account2, accountable: FactoryBot.create(:user), amount: Money.new(7))
        end
      end

      it { expect { perform }.to raise_error("trial balance must be zero") }
    end

    context "with invalid currencies" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        ) do
          debit(
            account: :account1, accountable: FactoryBot.create(:user), amount: Money.new(1, :ars)
          )
          credit(
            account: :account2, accountable: FactoryBot.create(:user), amount: Money.new(1, :ars)
          )
        end
      end

      it do
        expect { perform }.to raise_error(
          "invalid movement with account: account1, accountable: " +
            "User and currency: ars (NO mirror currency) for given entry1 entry in debits"
        )
      end
    end

    context "with mixed valid currencies" do
      def perform
        LedgerizerTestExecution.new.execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        ) do
          debit(
            account: :account1, accountable: FactoryBot.create(:user), amount: Money.new(1, :clp)
          )
          credit(
            account: :account2, accountable: FactoryBot.create(:user), amount: Money.new(1, :usd)
          )
        end
      end

      it { expect { perform }.to raise_error("No conversion rate known for 'USD' -> 'CLP'") }
    end

    context "with valid movements" do
      let(:expected_entry) do
        {
          entry_code: :entry1,
          entry_time: datetime,
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
          tenant: tenant, document: document, datetime: datetime
        ) do
          debit(data[:debit])
          credit(data[:credit])
        end
      end

      it { expect(tenant).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(debit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(credit_data) }
    end

    context "with defined conversion_amount" do
      let(:accountable1) { create(:user) }
      let(:accountable2) { create(:user) }
      let(:conversion_amount) { clp(600) }
      let(:mirror_currency) { "USD" }
      let(:expected_entry) do
        {
          entry_code: :entry1,
          entry_time: datetime,
          document: document,
          conversion_amount: nil,
          mirror_currency: nil
        }
      end

      let(:expected_mirror_entry) do
        {
          entry_code: :entry1,
          entry_time: datetime,
          document: document,
          conversion_amount: conversion_amount,
          mirror_currency: mirror_currency
        }
      end

      let(:debit_data) do
        {
          account: :account1,
          accountable: accountable1,
          amount: usd(2)
        }
      end

      let(:credit_data) do
        {
          account: :account2,
          accountable: accountable2,
          amount: usd(2)
        }
      end

      let(:mirror_debit_data) do
        {
          account: :account1,
          accountable: accountable1,
          amount: clp(1200),
          mirror_currency: mirror_currency
        }
      end

      let(:mirror_credit_data) do
        {
          account: :account2,
          accountable: accountable2,
          amount: clp(1200),
          mirror_currency: mirror_currency
        }
      end

      before do
        LedgerizerTestExecution.new(debit: debit_data, credit: credit_data).execute_entry1_entry(
          tenant: tenant,
          document: document,
          datetime: datetime,
          conversion_amount: conversion_amount
        ) do
          debit(data[:debit])
          credit(data[:credit])
        end
      end

      it { expect(tenant).to have_ledger_entry(expected_entry) }
      it { expect(tenant).to have_ledger_entry(expected_mirror_entry) }
      it { expect(Ledgerizer::Entry.first).to have_ledger_line(debit_data) }
      it { expect(Ledgerizer::Entry.first).to have_ledger_line(credit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(mirror_debit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(mirror_credit_data) }
    end

    context "with valid movements in another valid currency" do
      let(:expected_entry) do
        {
          entry_code: :entry1,
          entry_time: datetime,
          document: document
        }
      end

      let(:debit_data) do
        {
          account: :account1,
          accountable: create(:user),
          amount: usd(1)
        }
      end

      let(:credit_data) do
        {
          account: :account2,
          accountable: create(:user),
          amount: usd(1)
        }
      end

      before do
        LedgerizerTestExecution.new(debit: debit_data, credit: credit_data).execute_entry1_entry(
          tenant: tenant, document: document, datetime: datetime
        ) do
          debit(data[:debit])
          credit(data[:credit])
        end
      end

      it { expect(tenant).to have_ledger_entry(expected_entry) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(debit_data) }
      it { expect(Ledgerizer::Entry.last).to have_ledger_line(credit_data) }
    end

    context "with movement without accountable" do
      let(:expected_entry) do
        {
          entry_code: :entry3,
          entry_time: datetime,
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
          accountable: nil,
          amount: clp(1)
        }
      end

      before do
        LedgerizerTestExecution.new(debit: debit_data, credit: credit_data).execute_entry3_entry(
          tenant: tenant, document: document, datetime: datetime
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
          entry_time: datetime,
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
          tenant: tenant, document: document, datetime: datetime
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
