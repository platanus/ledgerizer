require "spec_helper"

# rubocop:disable RSpec/FilePath, RSpec/DescribedClass
RSpec.describe Ledgerizer::MoneyHelpers do
  describe '#available_currency?' do
    let(:currency) { "CLP" }

    define_test_class do
      include Ledgerizer::MoneyHelpers
    end

    def perform
      test_class.new.available_currency?(currency)
    end

    it { expect(perform).to eq(true) }

    context "with different currency" do
      let(:currency) { "USD" }

      it { expect(perform).to eq(true) }
    end

    context "with downcase currency" do
      let(:currency) { "clp" }

      it { expect(perform).to eq(true) }
    end

    context "with symbol currency" do
      let(:currency) { :clp }

      it { expect(perform).to eq(true) }
    end

    context "with invalid currency" do
      let(:currency) { "petro-del-mal" }

      it { expect(perform).to eq(false) }
    end
  end
end
# rubocop:enable RSpec/FilePath, RSpec/DescribedClass
