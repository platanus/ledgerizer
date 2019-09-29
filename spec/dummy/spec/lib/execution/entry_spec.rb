require "spec_helper"

RSpec.describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    build(
      :executable_entry,
      entry_definition: entry_definition,
      document: document_instance,
      entry_date: entry_date
    )
  end

  let(:entry_definition) do
    build(:entry_definition, code: entry_code, document: document)
  end

  let(:document) { :user }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  it { expect(execution_entry.entry_date).to eq(entry_date.to_date) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with non AR document" do
    let(:document_instance) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error("document must be an ActiveRecord model") }
  end

  context "with invalid AR document" do
    let(:document_instance) { create(:portfolio) }

    it { expect { execution_entry }.to raise_error(/invalid document Portfolio for given deposit/) }
  end

  context "with invalid date" do
    let(:entry_date) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid date given") }
  end

  describe "#add_movement" do
    let(:movement_type) { :debit }
    let(:account_name) { :cash }
    let(:account_type) { :asset }
    let(:accountable_instance) { create(:user) }
    let(:accountable) { :user }
    let(:amount) { clp(1000) }
    let(:base_currency) { :clp }
    let(:contra) { false }

    let(:account) do
      build(
        :account_definition,
        name: account_name,
        type: account_type,
        base_currency: base_currency,
        contra: contra
      )
    end

    def perform
      execution_entry.add_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    context "with no definition movement" do
      let(:error_msg) do
        'invalid movement cash with accountable User for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with existent definition movement" do
      before do
        entry_definition.add_movement(
          movement_type: movement_type,
          account: account,
          accountable: accountable
        )
      end

      it { expect { perform }.to change { execution_entry.movements.count }.from(0).to(1) }

      context "with non AR document" do
        let(:accountable_instance) { LedgerizerTest.new }

        it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
      end

      context "with invalid AR document" do
        let(:accountable_instance) { create(:portfolio) }

        it { expect { perform }.to raise_error(/accountable Portfolio for given deposit/) }
      end
    end
  end

  describe "#zero_trial_balance?" do
    let(:movements) { [] }

    def perform
      execution_entry.zero_trial_balance?
    end

    before do
      movements.each do |movement|
        execution_entry.movements << movement
      end
    end

    it { expect(perform).to eq(true) }

    context "with debit and credit accounts" do
      let(:m1) do
        build(
          :executable_movement,
          amount: clp(1),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset
            }
          }
        )
      end

      let(:m2) do
        build(
          :executable_movement,
          amount: clp(1),
          movement_def: {
            movement_type: :credit,
            account_def: {
              type: :liability
            }
          }
        )
      end

      let(:movements) { [m1, m2] }

      it { expect(perform).to eq(true) }
    end

    context "with contra account" do
      let(:m1) do
        build(
          :executable_movement,
          amount: clp(1),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset
            }
          }
        )
      end

      let(:m2) do
        build(
          :executable_movement,
          amount: clp(1),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset,
              contra: true
            }
          }
        )
      end

      let(:movements) { [m1, m2] }

      it { expect(perform).to eq(true) }
    end

    context "with multiple accounts" do
      let(:m1) do
        build(
          :executable_movement,
          amount: clp(10),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset
            }
          }
        )
      end

      let(:m2) do
        build(
          :executable_movement,
          amount: clp(7),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset,
              contra: true
            }
          }
        )
      end

      let(:m3) do
        build(
          :executable_movement,
          amount: clp(3),
          movement_def: {
            movement_type: :credit,
            account_def: {
              type: :liability
            }
          }
        )
      end

      let(:movements) { [m1, m2, m3] }

      it { expect(perform).to eq(true) }
    end

    context "when sum is not zero" do
      let(:m1) do
        build(
          :executable_movement,
          amount: clp(1),
          movement_def: {
            movement_type: :debit,
            account_def: {
              type: :asset
            }
          }
        )
      end

      let(:m2) do
        build(
          :executable_movement,
          amount: clp(7),
          movement_def: {
            movement_type: :credit,
            account_def: {
              type: :liability
            }
          }
        )
      end

      let(:movements) { [m1, m2] }

      it { expect(perform).to eq(false) }
    end
  end
end
