require "spec_helper"

RSpec.describe Ledgerizer::Definition::Entry do
  subject(:entry) { described_class.new(code: code, document: document) }

  let(:code) { :deposit }
  let(:document) { :portfolio }

  it { expect(entry.code).to eq(code) }
  it { expect(entry.document).to eq(document) }

  context "with string code" do
    let(:code) { "deposit" }

    it { expect(entry.code).to eq(code.to_sym) }
  end

  context "with invalid document" do
    let(:document) { :invalid }

    it { expect { entry }.to raise_error(/must be an ActiveRecord model name/) }
  end

  describe "#add_movement" do
    let(:entry_code) { :deposit }
    let(:accountable) { 'user' }
    let(:movement_type) { :debit }

    let(:account) do
      Ledgerizer::Definition::Account.new(name: :cash, type: :asset, base_currency: :usd)
    end

    def perform
      entry.add_movement(
        movement_type: movement_type, account: account, accountable: accountable
      )
    end

    def account_entries_count
      entry.movements
    end

    it { expect { perform }.to change { entry.movements.count }.from(0).to(1) }
    it { expect(perform.account_name).to eq(:cash) }
    it { expect(perform.accountable).to eq(:user) }
    it { expect(perform.movement_type).to eq(movement_type) }

    context "with existent movement type" do
      before { perform }

      it { expect { perform }.to raise_error(/cash with accountable user already/) }
    end

    context "with invalid accountable" do
      let(:accountable) { :invalid }

      it { expect { perform }.to raise_error(/must be an ActiveRecord model name/) }
    end
  end
end
