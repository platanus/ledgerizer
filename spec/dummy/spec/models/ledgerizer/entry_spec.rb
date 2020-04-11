require 'rails_helper'

module Ledgerizer
  RSpec.describe Entry, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_entry)).to be_valid
    end

    describe "associations" do
      it { is_expected.to belong_to(:tenant) }
      it { is_expected.to belong_to(:document) }
      it { is_expected.to have_many(:lines).dependent(:destroy) }
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:code) }
      it { is_expected.to validate_presence_of(:entry_date) }
    end

    it_behaves_like "ledgerizer lines related", :ledgerizer_entry
  end
end
