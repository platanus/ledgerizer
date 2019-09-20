require "spec_helper"

describe Ledgerizer::Execution::Movement do
  subject(:movement) do
    build(
      :executable_movement,
      movement_def: {
        accountable: accountable,
        movement_type: movement_type,
        account_def: {
          name: account_name,
          type: account_type,
          contra: contra,
          base_currency: base_currency
        }
      },
      accountable: accountable_instance,
      amount: amount
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

  it { expect(movement.credit?).to eq(false) }
  it { expect(movement.debit?).to eq(true) }
  it { expect(movement.contra).to eq(contra) }
  it { expect(movement.base_currency).to eq(:clp) }
  it { expect(movement.movement_type).to eq(movement_type) }

  context "with amount with currency that is not the tenant's currency" do
    let(:amount) { usd(1000) }

    it { expect { movement }.to raise_error("USD is not the account's currency") }
  end

  context "with not money amount" do
    let(:amount) { 1000 }

    it { expect { movement }.to raise_error("invalid money") }
  end

  context "with negative money amount" do
    let(:amount) { -clp(1) }

    it { expect { movement }.to raise_error("value needs to be greater than 0") }
  end

  context "with zero money amount" do
    let(:amount) { clp(0) }

    it { expect { movement }.to raise_error("value needs to be greater than 0") }
  end

  describe "signed_amount" do
    def perform
      movement.signed_amount
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
