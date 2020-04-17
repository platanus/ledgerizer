require 'rails_helper'

module Ledgerizer
  RSpec.describe Line, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_line)).to be_valid
    end

    describe "associations" do
      it { is_expected.to belong_to(:entry) }
      it { is_expected.to belong_to(:account) }
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:amount_cents) }
      it { is_expected.to validate_presence_of(:balance_cents) }
      it { is_expected.to monetize(:amount) }
      it { is_expected.to monetize(:balance) }
    end

    describe "#denormalize_attributes" do
      let(:line) { create(:ledgerizer_line) }

      it { expect(line.tenant).to eq(line.entry.tenant) }
      it { expect(line.document).to eq(line.entry.document) }
      it { expect(line.entry_code).to eq(line.entry.code) }
      it { expect(line.entry_time).to eq(line.entry.entry_time) }
      it { expect(line.accountable).to eq(line.account.accountable) }
      it { expect(line.account_name).to eq(line.account.name) }
      it { expect(line.account_type).to eq(line.account.account_type) }
    end

    describe "#filtered" do
      let(:filters) { double }
      let(:query) { double }

      def perform
        described_class.filtered(filters)
      end

      before do
        allow(Ledgerizer::FilteredLinesQuery).to receive(:new).and_return(query)
        allow(query).to receive(:all)
      end

      it "calls FilteredLinesQuery with valid params" do
        perform

        expect(Ledgerizer::FilteredLinesQuery).to have_received(:new)
          .with(relation: described_class, filters: filters)

        expect(query).to have_received(:all)
      end
    end

    describe "#amounts_sum" do
      let(:currency) { :clp }

      def perform
        described_class.amounts_sum(currency)
      end

      it { expect(perform).to eq(clp(0)) }

      context "with invalid currency" do
        let(:currency) { nil }

        it { expect { perform }.to raise_error(Money::Currency::UnknownCurrency) }
      end

      context "with lines" do
        before { create_list(:ledgerizer_line, 5, amount: clp(10)) }

        it { expect(perform).to eq(clp(50)) }

        context "with currency not matching lines" do
          let(:currency) { :usd }

          it { expect(perform).to eq(usd(0)) }
        end
      end
    end
  end
end
