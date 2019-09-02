require "spec_helper"

RSpec.describe Ledgerizer::Formatters do
  describe '#format_to_symbol_identifier' do
    let(:value) { :portfolio }

    define_test_class do
      include Ledgerizer::Formatters
    end

    def perform
      test_class.new.format_to_symbol_identifier(value)
    end

    it { expect(perform).to eq(:portfolio) }

    context "when string name" do
      let(:value) { "portfolio" }

      it { expect(perform).to eq(:portfolio) }
    end

    context "with camel model name" do
      let(:value) { "Portfolio" }

      it { expect(perform).to eq(:portfolio) }
    end

    context "with a model" do
      let(:value) { Portfolio }

      it { expect(perform).to eq(:portfolio) }
    end
  end

  describe '#format_currency' do
    let(:currency) { "CLP" }
    let(:strategy) { :symbol }
    let(:use_default) { true }

    define_test_class do
      include Ledgerizer::Formatters
    end

    def perform
      test_class.new.format_currency(currency, strategy: strategy, use_default: use_default)
    end

    it { expect(perform).to eq(:clp) }

    context "when different currency" do
      let(:currency) { "usd" }

      it { expect(perform).to eq(:usd) }
    end
  end
end
