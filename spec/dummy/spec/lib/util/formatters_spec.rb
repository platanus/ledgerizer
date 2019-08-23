require "spec_helper"

# rubocop:disable RSpec/FilePath, RSpec/DescribedClass
RSpec.describe Ledgerizer::Formatters do
  describe '#infer_active_record_class!' do
    let(:model_name) { :portfolio }

    define_test_class do
      include Ledgerizer::Formatters
    end

    def perform
      test_class.new.infer_active_record_class!(model_name)
    end

    it { expect(perform).to eq(Portfolio) }

    context "when string model name" do
      let(:model_name) { "portfolio" }

      it { expect(perform).to eq(Portfolio) }
    end

    context "with camel model name" do
      let(:model_name) { "Portfolio" }

      it { expect(perform).to eq(Portfolio) }
    end

    context "when model name is the class" do
      let(:model_name) { Portfolio }

      it { expect(perform).to eq(Portfolio) }
    end

    context "when name does not match AR model" do
      let(:model_name) { "invalid" }

      it { expect { perform }.to raise_error("name must be an ActiveRecord model name") }
    end
  end

  describe '#format_currency!' do
    let(:currency) { "CLP" }

    define_test_class do
      include Ledgerizer::Formatters
    end

    def perform
      test_class.new.format_currency!(currency)
    end

    it { expect(perform).to eq(:clp) }

    context "when different currency" do
      let(:currency) { "usd" }

      it { expect(perform).to eq(:usd) }
    end

    context "with invalid currency" do
      let(:currency) { "petro-del-mal" }

      it { expect { perform }.to raise_error("invalid currency 'petro-del-mal' given") }
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/DescribedClass
