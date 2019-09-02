require "spec_helper"

RSpec.describe Ledgerizer::Validators do
  describe '#validate_active_record_model_name!' do
    let(:model_name) { :portfolio }
    let(:error_prefix) { 'name' }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_active_record_model_name!(model_name, error_prefix)
    end

    def raise_invalid_model_error
      expect { perform }.to raise_error(/must be an ActiveRecord model name/)
    end

    it { expect(perform).to eq(true) }

    context "when string model name" do
      let(:model_name) { "portfolio" }

      it { raise_invalid_model_error }
    end

    context "with camel model name" do
      let(:model_name) { "Portfolio" }

      it { raise_invalid_model_error }
    end

    context "when model name is the class" do
      let(:model_name) { Portfolio }

      it { raise_invalid_model_error }
    end

    context "when name does not match AR model" do
      let(:model_name) { "invalid" }

      it { raise_invalid_model_error }
    end
  end

  describe '#validate_currency!' do
    let(:currency) { :clp }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_currency!(currency)
    end

    it { expect(perform).to eq(true) }

    context "when different currency" do
      let(:currency) { :usd }

      it { expect(perform).to eq(true) }
    end

    context "with string currency" do
      let(:currency) { "clp" }

      it { expect(perform).to eq(true) }
    end

    context "with upcase currency" do
      let(:currency) { "CLP" }

      it { expect(perform).to eq(true) }
    end

    context "with invalid currency" do
      let(:currency) { :petro }

      it { expect { perform }.to raise_error("invalid currency 'petro' given") }
    end
  end

  describe "#validate_tenant_instance!" do
    let(:error_prefix) { 'value' }

    define_test_class do
      include Ledgerizer::Definition::Dsl
      include Ledgerizer::Validators

      tenant(:portfolio)
    end

    def perform
      test_class.new.validate_tenant_instance!(instance, error_prefix)
    end

    context "with valid tenant" do
      let(:instance) { create(:portfolio) }

      it { expect(perform).to eq(true) }
    end

    context "with valid model that is not a tenant" do
      let(:instance) { create(:user) }

      it { expect { perform }.to raise_error("can't find tenant for given 'user' model") }
    end

    context "with non ActiveRecord instance" do
      let(:instance) { LedgerizerTest.new }

      it { expect { perform }.to raise_error("value must be an ActiveRecord model") }
    end
  end
end
