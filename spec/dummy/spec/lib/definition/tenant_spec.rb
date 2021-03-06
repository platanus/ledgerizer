require "spec_helper"

describe Ledgerizer::Definition::Tenant do
  subject(:tenant) { build(:tenant_definition, model_name: model_name, currency: currency) }

  let(:model_name) { "portfolio" }
  let(:currency) { "CLP" }

  describe "#model_name" do
    it { expect(tenant.model_name).to eq(:portfolio) }

    context "with symbol model name" do
      let(:model_name) { :portfolio }

      it { expect(tenant.model_name).to eq(:portfolio) }
    end

    context "with camel model name" do
      let(:model_name) { "Portfolio" }

      it { expect(tenant.model_name).to eq(:portfolio) }
    end
  end

  describe "#currency" do
    it { expect(tenant.currency).to eq(:clp) }

    context "with different currency" do
      let(:currency) { :usd }

      it { expect(tenant.currency).to eq(:usd) }
    end

    context "with invalid currency" do
      let(:currency) { "petro" }

      it { expect { tenant }.to raise_error("invalid currency 'petro' given") }
    end
  end

  describe "#add_account" do
    let(:account_name) { :cash }
    let(:account_type) { :asset }
    let(:account_currency) { nil }
    let(:contra) { true }

    def perform
      tenant.add_account(
        name: account_name,
        type: account_type,
        account_currency: account_currency,
        contra: contra
      )
    end

    def accounts
      tenant.send(:accounts)
    end

    it { expect(perform.name).to eq(account_name) }
    it { expect(perform.type).to eq(account_type) }
    it { expect(perform.contra).to eq(contra) }
    it { expect(perform.currency).to eq(tenant.currency) }
    it { expect(perform.mirror_currency).to be_nil }

    context "with repeated account" do
      let(:expected) do
        /cash account with clp currency and no mirror currency already exists/
      end

      before { perform }

      it { expect { perform }.to raise_error(expected) }
    end

    context "with different account currency" do
      let(:account_currency) { "USD" }

      before { perform }

      it { expect(accounts.first.name).to eq(account_name) }
      it { expect(accounts.first.type).to eq(account_type) }
      it { expect(accounts.first.contra).to eq(contra) }
      it { expect(accounts.first.currency).to eq(:usd) }
      it { expect(accounts.first.mirror_currency).to be_nil }

      it { expect(accounts.last.name).to eq(account_name) }
      it { expect(accounts.last.type).to eq(account_type) }
      it { expect(accounts.last.contra).to eq(contra) }
      it { expect(accounts.last.currency).to eq(:clp) }
      it { expect(accounts.last.mirror_currency).to eq(:usd) }
    end
  end

  describe "#add_entry" do
    let(:code) { :deposit }
    let(:document) { :deposit }

    def perform
      tenant.add_entry(code: code, document: document)
    end

    it { expect(perform.code).to eq(code) }
    it { expect(perform.document).to eq(:deposit) }

    context "with repeated account" do
      before { perform }

      it { expect { perform }.to raise_error("the deposit entry already exists in tenant") }
    end

    context "with invalid document" do
      let(:document) { :invalid }

      it { expect { perform }.to raise_error(/entry's document must be a snake_case/) }
    end
  end

  describe "#add_movement" do
    let(:entry_code) { :withdrawal }
    let(:account_name) { :cash }
    let(:movement_type) { :debit }
    let(:accountable) { 'user' }
    let!(:entry) { tenant.add_entry(code: :withdrawal, document: 'withdrawal') }
    let!(:account) { tenant.add_account(name: :cash, type: :asset, account_currency: :clp) }

    def movements
      tenant.add_movement(
        movement_type: movement_type,
        entry_code: entry_code,
        account_name: account_name,
        accountable: accountable
      )
    end

    it { expect { movements }.to change { entry.movements.count }.from(0).to(1) }
    it { expect(movements.first.account_name).to eq(:cash) }
    it { expect(movements.first.account_currency).to eq(:clp) }
    it { expect(movements.first.mirror_currency).to be_nil }
    it { expect(movements.first.accountable).to eq(:user) }

    context "with another account with same config but not tenant's currency" do
      let!(:another_account) do
        tenant.add_account(name: :cash, type: :asset, account_currency: :usd)
      end

      it { expect { movements }.to change { entry.movements.count }.from(0).to(3) }

      it { expect(movements.first.account_name).to eq(:cash) }
      it { expect(movements.first.account_currency).to eq(:clp) }
      it { expect(movements.first.mirror_currency).to be_nil }
      it { expect(movements.first.accountable).to eq(:user) }

      it { expect(movements.second.account_name).to eq(:cash) }
      it { expect(movements.second.account_currency).to eq(:usd) }
      it { expect(movements.second.mirror_currency).to be_nil }
      it { expect(movements.second.accountable).to eq(:user) }

      it { expect(movements.last.account_name).to eq(:cash) }
      it { expect(movements.last.account_currency).to eq(:clp) }
      it { expect(movements.last.mirror_currency).to eq(:usd) }
      it { expect(movements.last.accountable).to eq(:user) }
    end

    context "when provided entry code does not match existent entry" do
      let(:entry_code) { :register }

      it { expect { movements }.to raise_error('the register entry does not exist in tenant') }
    end

    context "when provided account name does not match existent entry" do
      let(:account_name) { :bank }

      it { expect { movements }.to raise_error('the bank account does not exist in tenant') }
    end
  end

  describe "#add_revaluation" do
    let(:name) { :rev1 }

    def perform
      tenant.add_revaluation(name: name)
    end

    it { expect(perform.name).to eq(name) }

    context "with repeated account" do
      before { perform }

      it { expect { perform }.to raise_error("the rev1 revaluation already exists in tenant") }
    end
  end

  describe "#create_revaluation_entries" do
    let(:name) { :rev1 }
    let(:entries_creator) do
      instance_double(Ledgerizer::Definition::RevaluationEntriesCreator)
    end

    def perform
      tenant.create_revaluation_entries(revaluation_name: name)
    end

    before do
      allow(Ledgerizer::Definition::RevaluationEntriesCreator).to receive(:new).and_return(
        entries_creator
      )
      allow(entries_creator).to receive(:create)
    end

    it "does not create entries" do
      expect(Ledgerizer::Definition::RevaluationEntriesCreator).not_to receive(:new)
      expect(entries_creator).not_to receive(:create)
      expect { perform }.to raise_error("missing rev1 revaluation")
    end

    context "with existent revaluation" do
      before { tenant.add_revaluation(name: name) }

      it "creates revaluation related entries and accounts" do
        expect(Ledgerizer::Definition::RevaluationEntriesCreator).to receive(:new)
          .with(tenant: tenant, revaluation: kind_of(Ledgerizer::Definition::Revaluation)).once
        expect(entries_creator).to receive(:create).with(no_args).once

        perform
      end
    end
  end
end
