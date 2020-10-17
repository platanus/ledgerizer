require "spec_helper"

describe Ledgerizer::RevaluationExecutor do
  let(:ledgerizer_config) { LedgerizerTestDefinition.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:accountable_instance) { create(:user) }
  let(:document_instance) { create(:deposit) }
  let(:entry_time) { "1984-06-03".to_datetime }
  let(:revaluation_time) { "1984-06-04".to_datetime }
  let(:revaluation_name) { :rev1 }
  let(:conversion_amount) { entry_conversion_amount }
  let(:entry_conversion_amount) { clp(600) }
  let(:currency) { :usd }
  let(:account_name) { :account1 }

  let(:revaluation_executor) do
    described_class.new(
      config: ledgerizer_config,
      tenant: tenant_instance,
      revaluation_name: revaluation_name,
      revaluation_time: revaluation_time,
      account_name: account_name,
      accountable: accountable_instance,
      conversion_amount: conversion_amount,
      currency: currency
    )
  end

  let(:debit_data) do
    {
      account: :account1,
      accountable: accountable_instance,
      amount: usd(2)
    }
  end

  let(:credit_data) do
    {
      account: :account2,
      accountable: accountable_instance,
      amount: usd(2)
    }
  end

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1, currencies: [:usd])
      liability(:account2, currencies: [:usd])

      revaluation(:rev1) do
        account(:account1, accountable: :user)
      end

      revaluation(:rev2) do
        account(:account2, accountable: :user)
      end

      entry(:entry1, document: :deposit) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
      end
    end
  end

  def perform
    revaluation_executor.execute
  end

  context "with existent mirror accounts" do
    before do
      LedgerizerTestExecution.new(debit: debit_data, credit: credit_data).execute_entry1_entry(
        tenant: tenant_instance, document: document_instance,
        datetime: entry_time, conversion_amount: entry_conversion_amount
      ) do
        debit(data[:debit])
        credit(data[:credit])
      end
    end

    it { expect(perform).to eq(false) }

    context "with asset revaluation" do
      let(:account_name) { :account1 }

      context "with positive revaluation" do
        let(:conversion_amount) { entry_conversion_amount + clp(100) }

        let(:expected_entry) do
          {
            entry_code: :positive_rev1_asset_revaluation,
            entry_time: revaluation_time,
            document: Ledgerizer::Revaluation.last,
            conversion_amount: nil,
            mirror_currency: "USD"
          }
        end

        let(:expected_m1) do
          {
            account_name: :positive_rev1,
            accountable: nil,
            mirror_currency: "USD",
            amount: clp(200),
            balance: clp(200)
          }
        end

        let(:expected_m2) do
          {
            account_name: :account1,
            accountable: accountable_instance,
            mirror_currency: "USD",
            amount: clp(200),
            balance: clp(1400)
          }
        end

        before { perform }

        it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
      end

      context "with negative revaluation" do
        let(:conversion_amount) { entry_conversion_amount - clp(100) }

        let(:expected_entry) do
          {
            entry_code: :negative_rev1_asset_revaluation,
            entry_time: revaluation_time,
            document: Ledgerizer::Revaluation.last,
            conversion_amount: nil,
            mirror_currency: "USD"
          }
        end

        let(:expected_m1) do
          {
            account_name: :negative_rev1,
            accountable: nil,
            mirror_currency: "USD",
            amount: clp(200),
            balance: clp(200)
          }
        end

        let(:expected_m2) do
          {
            account_name: :account1,
            accountable: accountable_instance,
            mirror_currency: "USD",
            amount: -clp(200),
            balance: clp(1000)
          }
        end

        before { perform }

        it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
      end
    end

    context "with liability revaluation" do
      let(:revaluation_name) { :rev2 }
      let(:account_name) { :account2 }

      context "with positive revaluation" do
        let(:conversion_amount) { entry_conversion_amount - clp(100) }

        let(:expected_entry) do
          {
            entry_code: :positive_rev2_liability_revaluation,
            entry_time: revaluation_time,
            document: Ledgerizer::Revaluation.last,
            conversion_amount: nil,
            mirror_currency: "USD"
          }
        end

        let(:expected_m1) do
          {
            account_name: :negative_rev2,
            accountable: nil,
            mirror_currency: "USD",
            amount: -clp(200),
            balance: -clp(200)
          }
        end

        let(:expected_m2) do
          {
            account_name: :account2,
            accountable: accountable_instance,
            mirror_currency: "USD",
            amount: -clp(200),
            balance: clp(1000)
          }
        end

        before { perform }

        it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
      end

      context "with negative revaluation" do
        let(:conversion_amount) { entry_conversion_amount + clp(100) }

        let(:expected_entry) do
          {
            entry_code: :negative_rev2_liability_revaluation,
            entry_time: revaluation_time,
            document: Ledgerizer::Revaluation.last,
            conversion_amount: nil,
            mirror_currency: "USD"
          }
        end

        let(:expected_m1) do
          {
            account_name: :positive_rev2,
            accountable: nil,
            mirror_currency: "USD",
            amount: -clp(200),
            balance: -clp(200)
          }
        end

        let(:expected_m2) do
          {
            account_name: :account2,
            accountable: accountable_instance,
            mirror_currency: "USD",
            amount: clp(200),
            balance: clp(1400)
          }
        end

        before { perform }

        it { expect(tenant_instance).to have_ledger_entry(expected_entry) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m1) }
        it { expect(tenant_instance.entries.last).to have_ledger_line(expected_m2) }
      end
    end
  end

  context "with missing account" do
    let(:error) do
      "missing Ledgerizer::Account with name account1 and currency USD"
    end

    it { expect { perform }.to raise_error(error) }
  end

  context "with missing mirror account" do
    let(:error) do
      "missing mirror Ledgerizer::Account with name account1 and mirror_currency USD"
    end

    before do
      create(
        :ledgerizer_account,
        tenant: tenant_instance,
        accountable: accountable_instance,
        name: account_name,
        account_type: :asset,
        currency: "USD",
        mirror_currency: nil
      )
    end

    it { expect { perform }.to raise_error(error) }
  end

  context "with invalid revaluation name" do
    let(:revaluation_name) { :invalid }

    it { expect { perform }.to raise_error("can't find revaluation with name: invalid") }
  end

  context "with invalid tenant" do
    let(:tenant_instance) { create(:user) }

    let(:error) do
      "tenant must be an instance of a class including LedgerizerTenant"
    end

    it { expect { perform }.to raise_error(error) }
  end

  context "with invalid account_name" do
    let(:account_name) { :invalid }

    let(:error) do
      "can't find account with name: invalid"
    end

    it { expect { perform }.to raise_error(error) }
  end

  context "with invalid conversion_amount" do
    let(:conversion_amount) { usd(20) }

    let(:error) do
      "given currency (usd) must be the tenant's currency (clp)"
    end

    it { expect { perform }.to raise_error(error) }
  end
end
