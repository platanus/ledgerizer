require 'rails_helper'

module Ledgerizer
  RSpec.describe Line, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_line)).to be_valid
    end

    describe "associations" do
      it { is_expected.to belong_to(:tenant) }
      it { is_expected.to belong_to(:document) }
      it { is_expected.to belong_to(:entry) }
      it { is_expected.to belong_to(:account) }
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:entry_code) }
      it { is_expected.to validate_presence_of(:entry_date) }
    end
  end
end
