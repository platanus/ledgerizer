require "spec_helper"

describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    build(
      :executable_entry,
      config: ledgerizer_config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_time: entry_time,
      conversion_amount: conversion_amount
    )
  end

  let(:ledgerizer_config) { LedgerizerTestDefinition.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:document) { :deposit }
  let(:document_instance) { create(:deposit) }
  let(:entry_code) { :deposit }
  let(:entry_time) { "1984-06-04" }
  let(:conversion_amount) { nil }
  let(:entry_instance_date) { entry_time }
  let(:mirror_currency) { nil }

  let(:entry) do
    create(
      :ledgerizer_entry,
      tenant: tenant_instance,
      document: document_instance,
      code: entry_code,
      entry_time: entry_instance_date,
      mirror_currency: mirror_currency,
      conversion_amount: conversion_amount
    )
  end

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1, currencies: [:usd])
      liability(:account2, currencies: [:usd])

      entry(:deposit, document: :deposit) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
      end
    end
  end

  it { expect(execution_entry.entry_time).to eq(entry_time.to_datetime) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with invalid tenant type" do
    let(:tenant_instance) { "tenant" }

    let(:error_msg) do
      "tenant must be an instance of a class including LedgerizerTenant"
    end

    it { expect { execution_entry }.to raise_error(error_msg) }
  end

  context "with invalid tenant" do
    let(:tenant_instance) { create(:user) }

    let(:error_msg) do
      "tenant must be an instance of a class including LedgerizerTenant"
    end

    it { expect { execution_entry }.to raise_error(error_msg) }
  end

  context "with non class document" do
    let(:document_instance) { LedgerizerTest.new }

    let(:error_msg) do
      "document must be an instance of a class including LedgerizerDocument"
    end

    it { expect { execution_entry }.to raise_error(error_msg) }
  end

  context "with invalid document" do
    let(:document_instance) { create(:portfolio) }

    let(:error_msg) do
      "document must be an instance of a class including LedgerizerDocument"
    end

    it { expect { execution_entry }.to raise_error(error_msg) }
  end

  context "with not valid entry code for given tenant" do
    let(:entry_code) { "buy" }

    it { expect { execution_entry }.to raise_error("invalid entry code buy for given tenant") }
  end

  context "with invalid date" do
    let(:entry_time) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid datetime given") }
  end

  context "with conversion_amount" do
    let(:conversion_amount) { "invalid" }

    it { expect { execution_entry }.to raise_error("invalid money") }
  end

  describe "#entry_instance" do
    def instance
      execution_entry.entry_instance
    end

    it { expect { instance }.to change(Ledgerizer::Entry, :count).from(0).to(1) }
    it { expect(instance).to be_a(Ledgerizer::Entry) }
    it { expect(instance.tenant).to eq(tenant_instance) }
    it { expect(instance.code).to eq(entry_code.to_s) }
    it { expect(instance.document).to eq(document_instance) }
    it { expect(instance.entry_time).to eq(entry_time.to_datetime) }
    it { expect(instance.conversion_amount).to be_nil }
    it { expect(instance.mirror_currency).to be_nil }

    context "with conversion amount" do
      let(:conversion_amount) { clp(600) }
      let(:account1_mirror_cur) { "USD" }
      let(:account2_mirror_cur) { "USD" }
      let(:accounts_from_new_movements) do
        [
          instance_double(Ledgerizer::Execution::Account, mirror_currency: account1_mirror_cur),
          instance_double(Ledgerizer::Execution::Account, mirror_currency: account2_mirror_cur)
        ]
      end

      before do
        allow(execution_entry).to receive(:accounts_from_new_movements)
          .and_return(accounts_from_new_movements)
      end

      it { expect(instance.conversion_amount).to eq(clp(600)) }
      it { expect(instance.mirror_currency).to eq("USD") }

      context "with mixed account mirror currencies" do
        let(:account1_mirror_cur) { "ARS" }

        it { expect { instance }.to raise_error("accounts with mixed mirror currency") }
      end
    end

    context "with persisted entry" do
      before { entry }

      it { expect { instance }.not_to change(Ledgerizer::Entry, :count) }
      it { expect(instance).to eq(entry) }
    end
  end

  describe "#add_new_movement" do
    let(:movement_type) { :debit }
    let(:amount) { clp(1000) }
    let(:account_name) { :account1 }
    let(:accountable_instance) { create(:user) }

    def perform
      execution_entry.add_new_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    it { expect { perform }.to change { execution_entry.new_movements.count }.from(0).to(1) }

    context "with valid non tenant currency" do
      let(:amount) { usd(1000) }

      it { expect { perform }.to change { execution_entry.new_movements.count }.from(0).to(1) }

      context "with defined conversion amount" do
        let(:conversion_amount) { clp(650) }

        it { expect { perform }.to change { execution_entry.new_movements.count }.from(0).to(1) }

        context "with invalid amount currency" do
          let(:amount) { ars(1000) }

          let(:error_msg) do
            'invalid movement with account: account1, accountable: ' +
              'User and currency: clp (ars mirror currency) for given deposit entry in debits'
          end

          it { expect { perform }.to raise_error(error_msg) }
        end
      end
    end

    context "with zero conversion amount" do
      let(:conversion_amount) { clp(0) }

      let(:error_msg) do
        "value needs to be greater than 0"
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with conversion amount currency different from tenant's currency" do
      let(:conversion_amount) { usd(6) }

      let(:error_msg) do
        "conversion amount currency (usd) is not the tenant's currency (clp)"
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with conversion amount currency equals to amount currency" do
      let(:conversion_amount) { clp(666) }

      let(:error_msg) do
        "the amount currency (clp) can't be the same as conversion amount currency"
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with non class accountable" do
      let(:accountable_instance) { LedgerizerTest.new }

      let(:error_msg) do
        "accountable must be an instance of a class including LedgerizerAccountable"
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with invalid accountable" do
      let(:accountable_instance) { create(:client) }

      let(:error_msg) do
        'invalid movement with account: account1, accountable: ' +
          'Client and currency: clp (NO mirror currency) for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition for matching given movement type" do
      let(:movement_type) { :credit }

      let(:error_msg) do
        'invalid movement with account: account1, accountable: ' +
          'User and currency: clp (NO mirror currency) for given deposit entry in credits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition for matching given account name" do
      let(:account_name) { :account2 }

      let(:error_msg) do
        'invalid movement with account: account2, accountable: ' +
          'User and currency: clp (NO mirror currency) for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with invalid amount" do
      let(:amount) { 666 }

      let(:error_msg) do
        'invalid money'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with invalid amount currency" do
      let(:amount) { ars(1000) }

      let(:error_msg) do
        'invalid movement with account: account1, accountable: ' +
          'User and currency: ars (NO mirror currency) for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end
  end

  describe "#related_accounts" do
    let(:account_name1) { :account1 }
    let(:account_name2) { :account2 }

    let(:account_type1) { :asset }
    let(:account_type2) { :liability }

    let(:accountable1) { create(:user) }
    let(:accountable2) { create(:user) }
    let(:accountable3) { create(:user) }

    def perform
      execution_entry.related_accounts.sort
    end

    context "with no conversion amount" do
      let(:conversion_amount) { nil }
      let(:mirror_currency) { nil }
      let(:amount) { clp(1) }

      let(:expected_accounts) do
        [
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable1,
            account_name: account_name1,
            account_type: account_type1,
            currency: amount.currency.to_s,
            mirror_currency: mirror_currency
          ),
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable2,
            account_name: account_name2,
            account_type: account_type2,
            currency: amount.currency.to_s,
            mirror_currency: mirror_currency
          ),
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable3,
            account_name: account_name2,
            account_type: account_type2,
            currency: amount.currency.to_s,
            mirror_currency: mirror_currency
          )
        ]
      end

      before do
        execution_entry.add_new_movement(
          movement_type: :debit,
          account_name: account_name1,
          accountable: accountable1,
          amount: amount
        )

        execution_entry.add_new_movement(
          movement_type: :credit,
          account_name: account_name2,
          accountable: accountable2,
          amount: amount
        )

        execution_entry.add_new_movement(
          movement_type: :credit,
          account_name: account_name2,
          accountable: accountable3,
          amount: amount
        )
      end

      it { expect(perform).to eq(expected_accounts) }

      context "with persisted entry adding a new account" do
        let(:accountable4) { create(:user) }
        let(:updated_expected_accounts) do
          expected_accounts + [
            build(
              :executable_account,
              tenant: tenant_instance,
              accountable: accountable4,
              account_name: account_name2,
              account_type: account_type2,
              currency: amount.currency.to_s,
              mirror_currency: mirror_currency
            )
          ]
        end

        before do
          create(
            :ledgerizer_line,
            entry: entry,
            account: create(
              :ledgerizer_account,
              tenant: tenant_instance,
              name: account_name2,
              accountable: accountable4,
              account_type: account_type2,
              currency: amount.currency.to_s,
              mirror_currency: mirror_currency
            )
          )
        end

        it { expect(perform).to eq(updated_expected_accounts) }
      end

      context "with previous entry not adding a new account" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            account: create(
              :ledgerizer_account,
              tenant: tenant_instance,
              name: account_name1,
              accountable: accountable1,
              account_type: account_type1,
              currency: amount.currency.to_s,
              mirror_currency: mirror_currency
            )
          )
        end

        it { expect(perform).to eq(expected_accounts) }
      end
    end

    context "with entry with defined conversion amount" do
      let(:conversion_amount) { clp(600) }
      let(:amount) { usd(1) }
      let(:mirror_currency) { "USD" }

      let(:expected_accounts) do
        [
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable1,
            account_name: account_name1,
            account_type: account_type1,
            currency: conversion_amount.currency.to_s,
            mirror_currency: amount.currency.to_s
          ),
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable2,
            account_name: account_name2,
            account_type: account_type2,
            currency: conversion_amount.currency.to_s,
            mirror_currency: amount.currency.to_s
          ),
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable3,
            account_name: account_name2,
            account_type: account_type2,
            currency: conversion_amount.currency.to_s,
            mirror_currency: amount.currency.to_s
          )
        ]
      end

      before do
        execution_entry.add_new_movement(
          movement_type: :debit,
          account_name: account_name1,
          accountable: accountable1,
          amount: amount
        )

        execution_entry.add_new_movement(
          movement_type: :credit,
          account_name: account_name2,
          accountable: accountable2,
          amount: amount
        )

        execution_entry.add_new_movement(
          movement_type: :credit,
          account_name: account_name2,
          accountable: accountable3,
          amount: amount
        )
      end

      it { expect(perform).to eq(expected_accounts) }

      context "with persisted entry adding a new account" do
        let(:accountable4) { create(:user) }
        let(:updated_expected_accounts) do
          expected_accounts + [
            build(
              :executable_account,
              tenant: tenant_instance,
              accountable: accountable4,
              account_name: account_name2,
              account_type: account_type2,
              currency: conversion_amount.currency.to_s,
              mirror_currency: amount.currency.to_s
            )
          ]
        end

        before do
          create(
            :ledgerizer_line,
            entry: entry,
            account: create(
              :ledgerizer_account,
              tenant: tenant_instance,
              name: account_name2,
              accountable: accountable4,
              account_type: account_type2,
              currency: conversion_amount.currency.to_s,
              mirror_currency: amount.currency.to_s
            )
          )
        end

        it { expect(perform).to eq(updated_expected_accounts) }
      end

      context "with previous entry not adding a new account" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            account: create(
              :ledgerizer_account,
              tenant: tenant_instance,
              name: account_name1,
              accountable: accountable1,
              account_type: account_type1,
              currency: conversion_amount.currency.to_s,
              mirror_currency: amount.currency.to_s
            )
          )
        end

        it { expect(perform).to eq(expected_accounts) }
      end
    end
  end
end
