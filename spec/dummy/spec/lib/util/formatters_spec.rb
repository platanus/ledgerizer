require "spec_helper"

RSpec.describe Ledgerizer::Formatters do
  let_test_class do
    include Ledgerizer::Formatters
  end

  describe '#format_to_symbol_identifier' do
    let(:value) { :portfolio }

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

    context "with blank value" do
      let(:value) { "" }

      it { expect(perform).to be_nil }
    end

    context "with nil value" do
      let(:value) { nil }

      it { expect(perform).to be_nil }
    end
  end

  describe '#format_to_upcase' do
    let(:value) { "lean" }

    def perform
      test_class.new.format_to_upcase(value)
    end

    it { expect(perform).to eq("LEAN") }

    context "with blank value" do
      let(:value) { "" }

      it { expect(perform).to be_nil }
    end

    context "with nil value" do
      let(:value) { nil }

      it { expect(perform).to be_nil }
    end
  end

  describe '#format_string_to_class' do
    let(:value) { :user }

    def perform
      test_class.new.format_string_to_class(value)
    end

    it { expect(perform).to eq(User) }
  end

  describe '#format_currency' do
    let(:currency) { "CLP" }
    let(:strategy) { :symbol }
    let(:use_default) { true }

    def perform
      test_class.new.format_currency(currency, strategy: strategy, use_default: use_default)
    end

    it { expect(perform).to eq(:clp) }

    context "when different currency" do
      let(:currency) { "usd" }

      it { expect(perform).to eq(:usd) }
    end

    context "when upcase strategy" do
      let(:strategy) { :upcase }

      it { expect(perform).to eq("CLP") }
    end

    context "with blank value" do
      let(:currency) { "" }

      it { expect(perform).to eq(:clp) }

      context "with no default value" do
        let(:use_default) { false }

        it { expect(perform).to eq(nil) }
      end
    end

    context "with nil value" do
      let(:currency) { nil }

      it { expect(perform).to eq(:clp) }
    end
  end

  describe '#format_ledgerizer_instance_to_sym' do
    let(:value) { create(:portfolio) }

    def perform
      test_class.new.format_ledgerizer_instance_to_sym(value)
    end

    it { expect(perform).to eq(:portfolio) }

    context "with non AR value" do
      let(:value) { build(:client) }

      it { expect(perform).to eq(:client) }
    end
  end
end
