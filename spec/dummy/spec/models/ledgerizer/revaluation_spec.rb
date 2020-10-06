require 'rails_helper'

module Ledgerizer
  describe Revaluation, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_revaluation)).to be_valid
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:amount_cents) }
      it { is_expected.to validate_presence_of(:revaluation_time) }
      it { is_expected.to monetize(:amount) }
    end
  end
end
