require "spec_helper"

RSpec.describe Ledgerizer::Validators do
  describe '#validate_active_record_model_name!' do
    let(:model_name) { :portfolio }
    let(:error_prefix) { 'name' }

    let_test_class do
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

    let_test_class do
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

  describe '#validate_date!' do
    let(:date) { "1984-06-04" }

    let_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_date!(date)
    end

    it { expect(perform).to eq(true) }

    context "when invalid date" do
      let(:date) { "invalid" }

      it { expect { perform }.to raise_error("invalid date given") }
    end
  end

  describe "#validate_money!" do
    let(:value) { clp(1000) }

    let_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_money!(value)
    end

    it { expect(perform).to eq(true) }

    context "with nil value" do
      let(:value) { nil }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with not money value" do
      let(:value) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end
  end

  describe "#validate_positive_money!" do
    let(:value) { clp(1000) }

    let_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_positive_money!(value)
    end

    it { expect(perform).to eq(true) }

    context "with not money value" do
      let(:value) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with 0 value" do
      let(:value) { clp(0) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with negative value" do
      let(:value) { clp(-1) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end
  end
end
