require "spec_helper"

describe Ledgerizer::Execution::EntryAccount do
  subject(:entry_account) do
    described_class.new(
      entry_account_definition: entry_account_definition,
      accountable: accountable_instance,
      amount: amount
    )
  end

  let(:entry_account_definition) do
    Ledgerizer::Definition::EntryAccount.new(
      account: account_definition,
      accountable: accountable,
      movement_type: movement_type
    )
  end

  let(:account_definition) do
    Ledgerizer::Definition::Account.new(
      name: account_name,
      type: account_type,
      contra: contra,
      base_currency: base_currency
    )
  end

  let(:accountable_instance) { create(:user) }
  let(:amount) { clp(1000) }
  let(:accountable) { :user }
  let(:movement_type) { :debit }
  let(:account_name) { :bank }
  let(:account_type) { :asset }
  let(:contra) { false }
  let(:base_currency) { "CLP" }

  context "with amount with currency that is not the tenant's currency" do
    let(:amount) { usd(1000) }

    it { expect { entry_account }.to raise_error("USD is not the account's currency") }
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
  
  describe "signed_amount" do
    def perform
      entry_account.signed_amount
    end

    context "with debit movement type" do
      let(:movement_type) { :debit }

      context "with debit account type" do
        let(:account_type) { :asset }

        it { expect(perform).to eq(amount) }

        context "with contra account" do
          let(:contra) { true }

          it { expect(perform).to eq(-amount) }
        end
      end

      context "with credit account type" do
        let(:account_type) { :liability }

        it { expect(perform).to eq(-amount) }
      end
    end

    context "with credit movement type" do
      let(:movement_type) { :credit }

      context "with credit account type" do
        let(:account_type) { :liability }

        it { expect(perform).to eq(amount) }

        context "with contra account" do
          let(:contra) { true }

          it { expect(perform).to eq(-amount) }
        end
      end

      context "with debit account type" do
        let(:account_type) { :asset }

        it { expect(perform).to eq(-amount) }
      end
    end
  end
end
