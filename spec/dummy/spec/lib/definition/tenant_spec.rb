require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Tenant do
  subject(:tenant) { described_class.new(model_name, currency) }

  let(:model_name) { "portfolio" }
  let(:model_class) { Portfolio }
  let(:currency) { nil }

  describe "#model_name" do
    it { expect(tenant.model_class).to eq(model_class) }

    context "with symbol model name" do
      let(:model_name) { :portfolio }

      it { expect(tenant.model_class).to eq(model_class) }
    end

    context "with camel model name" do
      let(:model_name) { "Portfolio" }

      it { expect(tenant.model_class).to eq(model_class) }
    end
  end

  describe "#currency" do
    it { expect(tenant.currency).to eq(:usd) }

    context "with different currency" do
      let(:currency) { :clp }

      it { expect(tenant.currency).to eq(:clp) }
    end

    context "with invalid currency" do
      let(:currency) { "platita" }

      it { expect { tenant }.to raise_error("invalid currency 'platita' given") }
    end
  end

  describe "#add_account" do
    let(:account_name) { :cash }
    let(:account_type) { :asset }

    def perform
      tenant.add_account(account_name, account_type)
    end

    it { expect(perform.name).to eq(account_name) }
    it { expect(perform.type).to eq(account_type) }

    context "with repeated account" do
      before { perform }

      it { expect { perform }.to raise_error("the cash account already exists in tenant") }
    end
  end

  describe "#add_entry" do
    let(:code) { :deposit }
    let(:document) { :portfolio }

    def perform
      tenant.add_entry(code, document)
    end

    it { expect(perform.code).to eq(code) }
    it { expect(perform.document).to eq(Portfolio) }

    context "with repeated account" do
      before { perform }

      it { expect { perform }.to raise_error("the deposit entry already exists in tenant") }
    end

    context "with invalid document" do
      let(:document) { :invalid }

      it { expect { perform }.to raise_error(/must be an ActiveRecord model name/) }
    end
  end

  describe "#add_debit" do
    let(:entry_code) { :deposit }
    let(:account_name) { :cash }
    let(:accountable) { 'portfolio' }
    let!(:entry) { tenant.add_entry(:deposit, 'portfolio') }
    let!(:account) { tenant.add_account(:cash, :asset) }

    def perform
      tenant.add_debit(entry_code, account_name, accountable)
    end

    it { expect { perform }.to change { entry.debits.count }.from(0).to(1) }
    it { expect(perform.account_name).to eq(:cash) }
    it { expect(perform.accountable).to eq(Portfolio) }

    context "when provided entry code does not match existent entry" do
      let(:entry_code) { :register }

      it { expect { perform }.to raise_error('the register entry does not exist in tenant') }
    end

    context "when provided account name does not match existent entry" do
      let(:account_name) { :bank }

      it { expect { perform }.to raise_error('the bank account does not exist in tenant') }
    end
  end
end
# rubocop:enable RSpec/FilePath
