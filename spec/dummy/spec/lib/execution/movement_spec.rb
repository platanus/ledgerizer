require "spec_helper"

describe Ledgerizer::Execution::Movement do
  subject(:movement) do
    build(
      :executable_movement,
      movement_def: movement_def,
      allow_negative_amount: allow_negative_amount,
      accountable: accountable_instance,
      amount: amount
    )
  end

  let(:movement_def) do
    {
      accountable: accountable,
      movement_type: movement_type,
      account_def: {
        name: account_name,
        type: account_type,
        contra: contra,
        currency: currency,
        mirror_currency: mirror_currency
      }
    }
  end

  let(:accountable_instance) { create(:user) }
  let(:amount) { clp(1000) }
  let(:accountable) { :user }
  let(:movement_type) { :debit }
  let(:account_name) { :bank }
  let(:account_type) { :asset }
  let(:contra) { false }
  let(:allow_negative_amount) { false }
  let(:currency) { "CLP" }
  let(:mirror_currency) { "USD" }

  it { expect(movement.credit?).to eq(false) }
  it { expect(movement.debit?).to eq(true) }
  it { expect(movement.contra).to eq(contra) }
  it { expect(movement.account_currency).to eq(:clp) }
  it { expect(movement.movement_type).to eq(movement_type) }
  it { expect(movement.mirror_currency).to eq(:usd) }

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

    context "with allow_negative_amount true" do
      let(:allow_negative_amount) { true }

      it { expect(movement.amount).to eq(amount) }
    end
  end

  context "with zero money amount" do
    let(:amount) { clp(0) }

    it { expect { movement }.to raise_error("value needs to be greater than 0") }
  end

  describe "signed_amount_cents" do
    def perform
      movement.signed_amount_cents
    end

    context "with positive value" do
      let(:account_type) { :asset }

      it { expect(perform).to eq(10000000) }
    end

    context "with negative value" do
      let(:account_type) { :liability }

      it { expect(perform).to eq(-10000000) }
    end
  end

  describe "signed_amount_currency" do
    def perform
      movement.signed_amount_currency
    end

    it { expect(perform).to eq("CLP") }

    context "with different amount's currency" do
      let(:currency) { "USD" }
      let(:amount) { usd(1000) }

      it { expect(perform).to eq("USD") }
    end
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

  describe "#==" do
    let(:other_accountable) { accountable_instance }
    let(:other_movement_definition) { movement.movement_definition }
    let(:other) do
      build(
        :executable_movement,
        movement_definition: other_movement_definition,
        accountable: other_accountable
      )
    end

    it { expect(movement).to eq(other) }

    context "with different defintion" do
      let(:other_movement_definition) { build(:movement_definition, movement_def) }

      it { expect(movement).not_to eq(other) }
    end

    context "with different accountable" do
      let(:other_accountable) { create(:user) }

      it { expect(movement).not_to eq(other) }
    end
  end
end
