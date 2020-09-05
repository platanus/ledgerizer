require "spec_helper"

RSpec.describe Money do
  describe '#available_currency?' do
    let(:currency) { "CLP" }

    def perform
      described_class.available_currency?(currency)
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

  describe '#convert_to' do
    let(:amount) { usd(2) }
    let(:conversion_amount) { clp(600) }

    def perform
      amount.convert_to(conversion_amount)
    end

    it { expect(perform).to eq(clp(1200)) }
  end
end
