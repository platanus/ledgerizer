require "spec_helper"

RSpec.describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
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

  context "with invalid tenant" do
    let(:tenant) { create(:user) }

    it { expect { execution_entry }.to raise_error("can't find tenant for given User model") }
  end

  context "with invalid document" do
    let(:document) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error("document must be an ActiveRecord model") }
  end

  context "with invalid entry_code" do
    let(:entry_code) { :register }

    it { expect { execution_entry }.to raise_error("invalid entry code register for given tenant") }
  end

  context "with invalid date" do
    let(:entry_date) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid date given") }
  end
end
