require 'rails_helper'

module Ledgerizer
  describe Entry, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_entry)).to be_valid
    end

    describe "associations" do
      it { is_expected.to have_many(:lines).dependent(:destroy) }
      it { is_expected.to have_many(:accounts) }
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:code) }
      it { is_expected.to validate_presence_of(:document_type) }
      it { is_expected.to validate_presence_of(:document_id) }
      it { is_expected.to validate_presence_of(:entry_time) }
      it { is_expected.to validate_presence_of(:tenant_type) }
      it { is_expected.to validate_presence_of(:tenant_id) }
    end

    it_behaves_like "ledgerizer lines related", :ledgerizer_entry

    describe "#to_table" do
      let(:collection) { described_class.all }
      let(:table_print_attrs) do
        %w{
          id
          entry_time
          document_id
          document_type
          code
          tenant_id
          tenant_type
        }
      end

      before { create_list(:ledgerizer_entry, 3) }

      it_behaves_like 'table print'
    end

    it_behaves_like "polymorphic attr", :ledgerizer_entry, :document, :deposit, :withdrawal
    it_behaves_like "polymorphic attr", :ledgerizer_entry, :tenant, :portfolio, :company
  end
end
