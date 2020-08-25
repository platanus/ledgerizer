require 'rails_helper'

module Ledgerizer
  describe Entry, type: :model do
    it "has a valid factory" do
      expect(build(:ledgerizer_entry)).to be_valid
    end

    describe "associations" do
      it { is_expected.to have_many(:lines).dependent(:destroy).inverse_of(:entry) }
      it { is_expected.to have_many(:accounts) }
    end

    describe "validations" do
      it { is_expected.to validate_presence_of(:code) }
      it { is_expected.to validate_presence_of(:document_type) }
      it { is_expected.to validate_presence_of(:document_id) }
      it { is_expected.to validate_presence_of(:entry_time) }
      it { is_expected.to validate_presence_of(:tenant_type) }
      it { is_expected.to validate_presence_of(:tenant_id) }
      it { is_expected.to monetize(:conversion_amount) }

      it_behaves_like 'currency', :ledgerizer_entry, :mirror_currency

      describe "conversion_amount presence" do
        let(:conversion_amount) { clp(0) }
        let(:mirror_currency) { nil }

        let(:entry) do
          build(
            :ledgerizer_entry,
            mirror_currency: mirror_currency,
            conversion_amount: conversion_amount
          )
        end

        it { expect(entry.save).to eq(true) }

        context "with conversion_amount greater than zero" do
          let(:conversion_amount) { clp(0.1) }

          it { expect(entry.save).to eq(false) }
        end

        context "with mirror_currency entry" do
          let(:mirror_currency) { "BTC" }

          it { expect(entry.save).to eq(false) }

          context "with conversion_amount greater than zero" do
            let(:conversion_amount) { clp(0.1) }

            it { expect(entry.save).to eq(true) }
          end
        end
      end
    end

    describe "mirror_currency?" do
      let(:entry) { build(:ledgerizer_entry) }

      it { expect(entry.mirror_currency?).to eq(false) }

      context "with mirror_currency entry" do
        let(:entry) { build(:ledgerizer_entry, :mirror_currency) }

        it { expect(entry.mirror_currency?).to eq(true) }
      end
    end

    it_behaves_like "ledgerizer lines related", :ledgerizer_entry

    describe "#to_table" do
      let(:collection) { described_class.all }
      let(:table_print_attrs) do
        %w{
          id
          conversion_amount_cents
          mirror_currency
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
