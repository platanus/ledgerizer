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
end
# rubocop:enable RSpec/FilePath
