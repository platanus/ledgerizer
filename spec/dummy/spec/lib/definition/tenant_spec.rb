require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Tenant do
  subject(:tenant) { described_class.new(model_class) }

  let(:model_class) { double }

  describe "#model_class" do
    it { expect(tenant.model_class).to eq(model_class) }
  end

  describe "#currency" do
    before { tenant.currency = :clp }

    it { expect(tenant.currency).to eq(:clp) }

    context "with nil currency" do
      before { tenant.currency = nil }

      it { expect(tenant.currency).to eq(:usd) }
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
