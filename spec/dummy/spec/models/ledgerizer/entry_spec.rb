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

    describe "#create_line!" do
      let(:cents) { 10000 }
      let(:currency) { "CLP" }

      let(:movement) do
        instance_double(
          "Ledgerizer::Execution::Movement",
          signed_amount_cents: cents,
          signed_amount_currency: currency
        )
      end

      let(:entry) { create(:ledgerizer_entry) }
      let(:account) { create(:ledgerizer_account) }

      def perform
        entry.create_line!(movement)
      end

      before do
        allow(entry.tenant).to receive(:find_or_create_account_from_executable_movement!).with(
          movement
        ).and_return(account)
      end

      context "with valid movement" do
        let(:expected_attributes) do
          {
            tenant: entry.tenant,
            entry_date: entry.entry_date,
            entry_code: entry.code,
            account_type: account.account_type,
            document: entry.document,
            account: account,
            accountable: account.accountable,
            account_name: account.name,
            amount_cents: cents,
            amount_currency: "CLP"
          }
        end

        it { expect { perform }.to change { entry.lines.count }.from(0).to(1) }
        it { expect(perform).to have_attributes(expected_attributes) }
      end

      context "with invalid attributes" do
        let(:account) { nil }

        it { expect { perform }.to raise_error(ActiveRecord::RecordInvalid) }
      end
    end
  end
end
