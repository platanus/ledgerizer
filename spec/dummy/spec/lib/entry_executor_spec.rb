require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
  describe '#initialize' do
    subject(:executor) do
      described_class.new(
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    let(:tenant) { create(:portfolio) }
    let(:document) { create(:user) }
    let(:entry_code) { :deposit }
    let(:entry_date) { "1984-06-04" }

    define_test_class do
      include Ledgerizer::Definition::Dsl

      tenant(:portfolio, currency: :clp) do
        asset(:cash)

        entry(:deposit, document: :user) do
          credit(account: :cash, accountable: :user)
        end
      end
    end

    it { expect(executor).to be_a(Ledgerizer::EntryExecutor) }

    context "with invalid tenant" do
      let(:tenant) { create(:user) }

      it { expect { executor }.to raise_error("can't find tenant for given User model") }
    end

    context "with invalid document" do
      let(:document) { LedgerizerTest.new }

      it { expect { executor }.to raise_error("document must be an ActiveRecord model") }
    end

    context "with invalid entry_code" do
      let(:entry_code) { :register }

      it { expect { executor }.to raise_error("invalid entry code register for given tenant") }
    end
  end

  it_behaves_like 'add executor entry item', :credit
  it_behaves_like 'add executor entry item', :debit
end
