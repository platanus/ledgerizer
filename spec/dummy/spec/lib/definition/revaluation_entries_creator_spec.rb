require "spec_helper"

describe Ledgerizer::Definition::RevaluationEntiresCreator do
  subject(:creator) { described_class.new(tenant: tenant, revaluation: revaluation) }

  let(:tenant_currency) { "CLP" }
  let(:tenant) { build(:tenant_definition, currency: tenant_currency) }
  let(:tenant_accounts) { tenant.send(:accounts) }
  let(:entries) { tenant.send(:entries) }
  let(:first_entry) { entries.first }
  let(:first_entry_movements) { first_entry.movements }
  let(:second_entry) { entries.second }
  let(:second_entry_movements) { second_entry.movements }

  let(:revaluation_name) { :rev }
  let(:revaluation) { build(:revaluation_definition, name: revaluation_name) }
  let(:revaluation_accounts) { revaluation.accounts }

  def perform
    creator.create
  end

  def revaluation_accounts
    revaluation.accounts
  end

  it { expect(revaluation.accounts.count).to eq(0) }
  it { expect(tenant_accounts.count).to eq(0) }
  it { expect(entries.count).to eq(0) }

  context "with asset revaluation" do
    before do
      tenant.add_account(name: :account1, type: :asset, account_currency: :usd)
      revaluation.add_account(account_name: :account1, accountable: :user)
      perform
    end

    it { expect(revaluation.accounts.count).to eq(1) }
    it { expect(tenant_accounts.count).to eq(4) }
    it { expect(entries.count).to eq(2) }

    it { expect(first_entry.code).to eq(:positive_rev_asset_revaluation) }
    it { expect(first_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(first_entry.movements.count).to eq(2) }

    it { expect(first_entry_movements.first.account_name).to eq(:positive_rev) }
    it { expect(first_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.first.accountable).to be_nil }
    it { expect(first_entry_movements.first.movement_type).to eq(:credit) }

    it { expect(first_entry_movements.second.account_name).to eq(:account1) }
    it { expect(first_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.second.accountable).to eq(:user) }
    it { expect(first_entry_movements.second.movement_type).to eq(:debit) }

    it { expect(second_entry.code).to eq(:negative_rev_asset_revaluation) }
    it { expect(second_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(second_entry.movements.count).to eq(2) }

    it { expect(second_entry_movements.first.account_name).to eq(:negative_rev) }
    it { expect(second_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.first.accountable).to be_nil }
    it { expect(second_entry_movements.first.movement_type).to eq(:debit) }

    it { expect(second_entry_movements.second.account_name).to eq(:account1) }
    it { expect(second_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.second.accountable).to eq(:user) }
    it { expect(second_entry_movements.second.movement_type).to eq(:credit) }
  end

  context "with multiple asset revaluation" do
    before do
      tenant.add_account(name: :account1, type: :asset, account_currency: :usd)
      tenant.add_account(name: :account2, type: :asset, account_currency: :usd)
      revaluation.add_account(account_name: :account1, accountable: :user)
      revaluation.add_account(account_name: :account2, accountable: :user)
      perform
    end

    it { expect(revaluation.accounts.count).to eq(2) }
    it { expect(tenant_accounts.count).to eq(6) }
    it { expect(entries.count).to eq(2) }

    it { expect(first_entry.code).to eq(:positive_rev_asset_revaluation) }
    it { expect(first_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(first_entry.movements.count).to eq(3) }

    it { expect(first_entry_movements.first.account_name).to eq(:positive_rev) }
    it { expect(first_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.first.accountable).to be_nil }
    it { expect(first_entry_movements.first.movement_type).to eq(:credit) }

    it { expect(first_entry_movements.second.account_name).to eq(:account1) }
    it { expect(first_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.second.accountable).to eq(:user) }
    it { expect(first_entry_movements.second.movement_type).to eq(:debit) }

    it { expect(first_entry_movements.third.account_name).to eq(:account2) }
    it { expect(first_entry_movements.third.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.third.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.third.accountable).to eq(:user) }
    it { expect(first_entry_movements.third.movement_type).to eq(:debit) }

    it { expect(second_entry.code).to eq(:negative_rev_asset_revaluation) }
    it { expect(second_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(second_entry.movements.count).to eq(3) }

    it { expect(second_entry_movements.first.account_name).to eq(:negative_rev) }
    it { expect(second_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.first.accountable).to be_nil }
    it { expect(second_entry_movements.first.movement_type).to eq(:debit) }

    it { expect(second_entry_movements.second.account_name).to eq(:account1) }
    it { expect(second_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.second.accountable).to eq(:user) }
    it { expect(second_entry_movements.second.movement_type).to eq(:credit) }

    it { expect(second_entry_movements.third.account_name).to eq(:account2) }
    it { expect(second_entry_movements.third.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.third.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.third.accountable).to eq(:user) }
    it { expect(second_entry_movements.third.movement_type).to eq(:credit) }
  end

  context "with liability revaluation" do
    before do
      tenant.add_account(name: :account1, type: :liability, account_currency: :usd)
      revaluation.add_account(account_name: :account1, accountable: :user)
      perform
    end

    it { expect(revaluation.accounts.count).to eq(1) }
    it { expect(tenant_accounts.count).to eq(4) }
    it { expect(entries.count).to eq(2) }

    it { expect(first_entry.code).to eq(:positive_rev_liability_revaluation) }
    it { expect(first_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(first_entry.movements.count).to eq(2) }

    it { expect(first_entry_movements.first.account_name).to eq(:negative_rev) }
    it { expect(first_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.first.accountable).to be_nil }
    it { expect(first_entry_movements.first.movement_type).to eq(:credit) }

    it { expect(first_entry_movements.second.account_name).to eq(:account1) }
    it { expect(first_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(first_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(first_entry_movements.second.accountable).to eq(:user) }
    it { expect(first_entry_movements.second.movement_type).to eq(:debit) }

    it { expect(second_entry.code).to eq(:negative_rev_liability_revaluation) }
    it { expect(second_entry.document).to eq(:"ledgerizer/revaluation") }
    it { expect(second_entry.movements.count).to eq(2) }

    it { expect(second_entry_movements.first.account_name).to eq(:positive_rev) }
    it { expect(second_entry_movements.first.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.first.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.first.accountable).to be_nil }
    it { expect(second_entry_movements.first.movement_type).to eq(:debit) }

    it { expect(second_entry_movements.second.account_name).to eq(:account1) }
    it { expect(second_entry_movements.second.account_currency).to eq(:clp) }
    it { expect(second_entry_movements.second.mirror_currency).to eq(:usd) }
    it { expect(second_entry_movements.second.accountable).to eq(:user) }
    it { expect(second_entry_movements.second.movement_type).to eq(:credit) }
  end

  context "with accounts with invalid account type" do
    before do
      tenant.add_account(name: :account1, type: :expense, account_currency: :usd)
      revaluation.add_account(account_name: :account1, accountable: :user)
    end

    it { expect { perform }.to raise_error("account1 must be asset or liability to be revalued") }
  end

  context "with missing tenant account" do
    before do
      revaluation.add_account(account_name: :account1, accountable: :user)
    end

    it { expect { perform }.to raise_error("undefined account1 account for rev revaluation") }
  end

  context "with no mirror account" do
    before do
      tenant.add_account(name: :account1, type: :asset, account_currency: :clp)
      revaluation.add_account(account_name: :account1, accountable: :user)
    end

    it { expect { perform }.to raise_error(/only accounts with a currency other than the tenant/) }
  end

  context "with missing revaluation account" do
    before do
      tenant.add_account(name: :account1, type: :asset, account_currency: :usd)
    end

    it { expect { perform }.to raise_error("missing revaluation accounts") }
  end
end
