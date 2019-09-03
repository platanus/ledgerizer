require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
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

  describe '#initialize' do
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

  describe "#add_credit" do
    let(:account_name) { :cash }
    let(:accountable) { create(:user) }
    let(:amount) { clp(1000) }
    let(:expected_item) do
      {
        accountable: accountable,
        currency: "CLP",
        account_name: :cash,
        amount: amount
      }
    end

    def perform
      executor.add_credit(account_name: account_name, accountable: accountable, amount: amount)
    end

    it { expect(perform).to eq(expected_item) }
    it { expect { perform }.to change { executor.credits.count }.from(0).to(1) }

    context "with amount with currency that is not the tenant's currency" do
      let(:amount) { usd(1000) }

      it { expect { perform }.to raise_error("USD is not the tenant's currency") }
    end

    context "with not money amount" do
      let(:amount) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with negative money amount" do
      let(:amount) { -clp(1) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with negative money amount" do
      let(:amount) { clp(0) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with invalid account name" do
      let(:account_name) { :bank }

      it { expect { perform }.to raise_error(/invalid entry account bank with accountable/) }
    end

    context "with invalid accountable" do
      let(:accountable) { create(:portfolio) }

      it { expect { perform }.to raise_error(/invalid entry account cash with accountable Port/) }
    end

    context "with non AR accountable" do
      let(:accountable) { "not active record model" }

      it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
    end
  end
end
