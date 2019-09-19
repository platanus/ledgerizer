require "spec_helper"

RSpec.describe Ledgerizer::Execution::EntryAccount do
  subject(:entry_account) do
    described_class.new(
      executable_entry: executable_entry,
      movement_type: movement_type,
      account_name: account_name,
      accountable: accountable,
      amount: amount
    )
  end

  let(:tenant) { create(:portfolio) }
  let(:document) { create(:user) }
  let(:entry_code) { :entry1 }
  let(:entry_date) { "1984-06-04" }

  let(:executable_entry) do
    Ledgerizer::Execution::Entry.new(
      tenant: tenant,
      document: document,
      entry_code: entry_code,
      entry_date: entry_date
    )
  end

  let(:movement_type) { :debit }
  let(:account_name) { :account1 }
  let(:accountable) { create(:user) }
  let(:amount) { clp(1000) }
  let(:expected_item) do
    {
      accountable: accountable,
      currency: "CLP",
      account_name: :account1,
      amount: amount
    }
  end

  define_test_class do
    include Ledgerizer::Definition::Dsl

    tenant(:portfolio, currency: :clp) do
      asset(:account1)
      liability(:account2)
      liability(:account3)
      asset(:account4)
      asset(:account5, contra: true)
      liability(:account6, contra: true)

      entry(:entry1, document: :user) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
        debit(account: :account3, accountable: :user)
        credit(account: :account4, accountable: :user)
        debit(account: :account5, accountable: :user)
        credit(account: :account6, accountable: :user)
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

    it { expect { entry_account }.to raise_error(/invalid entry account account1 with accounta/) }
  end

  context "with non AR accountable" do
    let(:accountable) { "not active record model" }

    it { expect { entry_account }.to raise_error("accountable must be an ActiveRecord model") }
  end

  describe "signed_amount" do
    def perform
      entry_account.signed_amount
    end

    context "with debit movement type" do
      let(:movement_type) { :debit }

      context "with debit account" do
        let(:account_name) { :account1 }

        it { expect(perform).to eq(amount) }

        context "with contra account" do
          let(:account_name) { :account5 }

          it { expect(perform).to eq(-amount) }
        end
      end

      context "with credit account" do
        let(:account_name) { :account3 }

        it { expect(perform).to eq(-amount) }
      end
    end

    context "with credit movement type" do
      let(:movement_type) { :credit }

      context "with credit account" do
        let(:account_name) { :account2 }

        it { expect(perform).to eq(amount) }

        context "with contra account" do
          let(:account_name) { :account6 }

          it { expect(perform).to eq(-amount) }
        end
      end

      context "with debit account" do
        let(:account_name) { :account4 }

        it { expect(perform).to eq(-amount) }
      end
    end
  end
end
