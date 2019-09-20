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
      it { is_expected.to monetize(:amount) }
    end

    describe "#denormalize_attributes" do
      let(:line) { create(:ledgerizer_line) }

      it { expect(line.tenant).to eq(line.entry.tenant) }
      it { expect(line.document).to eq(line.entry.document) }
      it { expect(line.entry_code).to eq(line.entry.code) }
      it { expect(line.entry_date).to eq(line.entry.entry_date) }
    end
  end
end
