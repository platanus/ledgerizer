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
end
# rubocop:enable RSpec/FilePath
