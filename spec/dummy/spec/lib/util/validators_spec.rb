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

  describe '#format_currency!' do
    let(:currency) { "CLP" }

    define_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_currency!(currency)
    end

    it { expect(perform).to eq(true) }

    context "when different currency" do
      let(:currency) { "USD" }

      it { expect(perform).to eq(true) }
    end

    context "when lower currency" do
      let(:currency) { "usd" }

      it { expect(perform).to eq(true) }
    end

    context "when symbol currency" do
      let(:currency) { "usd" }

      it { expect(perform).to eq(true) }
    end

    context "with invalid currency" do
      let(:currency) { "petro-del-mal" }

      it { expect { perform }.to raise_error("invalid currency 'petro-del-mal' given") }
    end
  end
end
