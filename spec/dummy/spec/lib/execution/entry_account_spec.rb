require "spec_helper"

RSpec.describe Ledgerizer::Execution::EntryAccount do
  subject(:entry_account) do
    described_class.new(
      executable_entry: executable_entry,
      account_type: type,
      account_name: account_name,
      accountable: accountable,
      amount: amount
    )
  end

  let(:tenant) { create(:portfolio) }
  let(:document) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  let(:executable_entry) do
    Ledgerizer::Execution::Entry.new(
      tenant: tenant,
      document: document,
      entry_code: entry_code,
      entry_date: entry_date
    )
  end

  let(:type) { :debit }
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

  define_test_class do
    include Ledgerizer::Definition::Dsl

    tenant(:portfolio, currency: :clp) do
      asset(:cash)

      entry(:deposit, document: :user) do
        debit(account: :cash, accountable: :user)
      end
    end
  end

  context "with amount with currency that is not the tenant's currency" do
    let(:amount) { usd(1000) }

    it { expect { entry_account }.to raise_error("USD is not the tenant's currency") }
  end

  context "with not money amount" do
    let(:amount) { 1000 }

    it { expect { entry_account }.to raise_error("invalid money") }
  end

  context "with negative money amount" do
    let(:amount) { -clp(1) }

    it { expect { entry_account }.to raise_error("value needs to be greater than 0") }
  end

  context "with zero money amount" do
    let(:amount) { clp(0) }

    it { expect { entry_account }.to raise_error("value needs to be greater than 0") }
  end

  context "with invalid account name" do
    let(:account_name) { :bank }

    it { expect { entry_account }.to raise_error(/invalid entry account bank with accountable/) }
  end

  context "with invalid accountable" do
    let(:accountable) { create(:portfolio) }

    it { expect { entry_account }.to raise_error(/invalid entry account cash with accountable P/) }
  end

  context "with non AR accountable" do
    let(:accountable) { "not active record model" }

    it { expect { entry_account }.to raise_error("accountable must be an ActiveRecord model") }
  end
end
