require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
  describe '#initialize' do
    let(:tenant) { create(:portfolio) }
    let(:document) { create(:user) }
    let(:entry_code) { :deposit }
    let(:entry_date) { "1984-06-04" }

    define_test_class do
      include Ledgerizer::Definition::Dsl

      tenant(:portfolio) do
        entry(:deposit, document: :user)
      end
    end

    def perform
      described_class.new(
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    it { expect(perform).to be_a(Ledgerizer::EntryExecutor) }

    context "with invalid tenant" do
      let(:tenant) { create(:user) }

      it { expect { perform }.to raise_error("can't find tenant for given User model") }
    end

    context "with invalid document" do
      let(:document) { LedgerizerTest.new }

      it { expect { perform }.to raise_error("document must be an ActiveRecord model") }
    end

    context "with invalid entry_code" do
      let(:entry_code) { :register }

      it { expect { perform }.to raise_error("invalid entry code register for given tenant") }
    end
  end
end
