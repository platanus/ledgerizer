require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Config do
  subject(:config) { described_class.new }

  describe "#add_tenant" do
    let(:model_name) { "portfolio" }
    let(:model_class) { Portfolio }

    def perform
      config.add_tenant(model_name)
    end

    it { expect(perform.model_class).to eq(Portfolio) }

    context "with repeated tenant" do
      before { perform }

      it { expect { perform }.to raise_error(Ledgerizer::ConfigError, 'the tenant already exists') }
    end
  end

  describe "#find_tenant" do
    let(:model_name) { "portfolio" }
    let(:model_class) { Portfolio }

    def perform
      config.find_tenant(model_class)
    end

    it { expect(perform).to be_nil }

    context "with repeated tenant" do
      before { config.add_tenant(model_name) }

      it { expect(perform).to be_a(Ledgerizer::Definition::Tenant) }
    end
  end
end
# rubocop:enable RSpec/FilePath
