require "spec_helper"

RSpec.describe Ledgerizer::Validators do
  describe '#validate_ledgerized_class_name!' do
    let(:value) { :portfolio }
    let(:error_prefix) { 'tenant' }
    let(:ledgerizer_mixin) { LedgerizerTenant }

    let_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_ledgerized_class_name!(value, error_prefix, ledgerizer_mixin)
    end

    it { expect(perform).to eq(true) }

    context "with string value" do
      let(:value) { "portfolio" }

      it { expect(perform).to eq(true) }
    end

    context "with symbol value" do
      let(:value) { :portfolio }

      it { expect(perform).to eq(true) }
    end

    context "with camel value" do
      let(:value) { "Portfolio" }

      it { expect(perform).to eq(true) }
    end

    context "when value is the class" do
      let(:value) { Portfolio }

      it { expect(perform).to eq(true) }
    end

    context "with value not matching ledgerizer mixin" do
      let(:value) { "deposit" }

      it { expect { perform }.to raise_error(/tenant must include LedgerizerTenant/) }
    end

    context "when value is not an AR model" do
      let(:value) { "withdrawal" }

      it { expect { perform }.to raise_error(/tenant must include LedgerizerTenant/) }

      context "with matching ledgerizer_mixin" do
        let(:ledgerizer_mixin) { LedgerizerDocument }

        it { expect(perform).to eq(true) }
      end
    end

    context "when name does not match AR model" do
      let(:value) { "invalid" }

      it { expect { perform }.to raise_error(/must be a snake_case representation of a Ruby/) }
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

  describe '#validate_datetime!' do
    let(:datetime) { "1984-06-04".to_datetime }

    let_test_class do
      include Ledgerizer::Validators
    end

    def perform
      test_class.new.validate_datetime!(datetime)
    end

    it { expect(perform).to eq(true) }

    context "when invalid date" do
      let(:datetime) { "invalid" }

      it { expect { perform }.to raise_error("invalid datetime given") }
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
