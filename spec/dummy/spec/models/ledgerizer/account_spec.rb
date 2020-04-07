require 'rails_helper'

module Ledgerizer
  RSpec.describe Account, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_account)).to be_valid
    end

    describe "associations" do
      it { is_expected.to belong_to(:tenant) }
      it { is_expected.to belong_to(:accountable).optional }
      it { is_expected.to have_many(:lines).dependent(:destroy) }
    end

    describe "validations" do
      it { is_expected.to enumerize(:account_type).in(Ledgerizer::Definition::Account::TYPES) }
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_presence_of(:account_type) }
      it { is_expected.to validate_presence_of(:currency) }
      it { is_expected.to validate_presence_of(:balance_cents) }
      it { is_expected.to monetize(:balance) }

      it_behaves_like 'currency', :ledgerizer_account
    end

    it_behaves_like "ledgerizer lines related", :ledgerizer_account
  end
end
