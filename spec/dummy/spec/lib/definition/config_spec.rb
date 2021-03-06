require "spec_helper"

RSpec.describe Ledgerizer::Definition::Config do
  subject(:config) { described_class.new }

  describe "#add_tenant" do
    let(:model_name) { "portfolio" }

    def perform
      config.add_tenant(model_name: model_name)
    end

    it { expect(perform.model_name).to eq(:portfolio) }

    context "with repeated tenant" do
      before { perform }

      it { expect { perform }.to raise_error(Ledgerizer::ConfigError, 'the tenant already exists') }
    end
  end

  describe "#find_tenant" do
    let(:value) { :portfolio }

    def perform
      config.find_tenant(value)
    end

    it { expect(perform).to be_nil }

    context "with existent tenant" do
      before { config.add_tenant(model_name: :portfolio) }

      it { expect(perform).to be_a(Ledgerizer::Definition::Tenant) }

      context "with AR model value" do
        let(:value) { create(:portfolio) }

        it { expect(perform).to be_a(Ledgerizer::Definition::Tenant) }
      end
    end
  end

  describe "#get_tenant_currency" do
    let(:value) { :portfolio }

    def perform
      config.get_tenant_currency(value)
    end

    before { config.add_tenant(model_name: :portfolio) }

    it { expect(perform).to eq(:clp) }

    context "with invalid tenant" do
      let(:value) { :invalid }

      it { expect { perform }.to raise_error("tenant's config does not exist") }
    end
  end
end
