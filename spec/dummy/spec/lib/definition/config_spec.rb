require "spec_helper"

RSpec.describe Ledgerizer::Definition::Config do
  subject(:config) { described_class.new }

  describe "#add_tenant" do
    let(:model_class_name) { "portfolio" }

    def perform
      config.add_tenant(model_class_name)
    end

    it { expect(perform.model_class_name).to eq(:portfolio) }

    context "with repeated tenant" do
      before { perform }

      it { expect { perform }.to raise_error(Ledgerizer::ConfigError, 'the tenant already exists') }
    end
  end

  describe "#find_tenant" do
    let(:model_class_name) { :portfolio }

    def perform
      config.find_tenant(model_class_name)
    end

    it { expect(perform).to be_nil }

    context "with existent tenant" do
      before { config.add_tenant(model_class_name) }

      it { expect(perform).to be_a(Ledgerizer::Definition::Tenant) }
    end
  end
end
