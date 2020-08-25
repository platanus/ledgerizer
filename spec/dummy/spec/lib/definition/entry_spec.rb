require "spec_helper"

describe Ledgerizer::Definition::Entry do
  subject(:entry) { build(:entry_definition, code: code, document: document) }

  let(:code) { :deposit }
  let(:document) { :deposit }

  it { expect(entry.code).to eq(code) }
  it { expect(entry.document).to eq(document) }

  context "with string code" do
    let(:code) { "deposit" }

    it { expect(entry.code).to eq(code.to_sym) }
  end

  context "with invalid document" do
    let(:document) { :invalid }

    it { expect { entry }.to raise_error(/entry's document must be a snake_case representation/) }
  end

  describe "#add_movement" do
    let(:entry_code) { :deposit }
    let(:accountable) { 'user' }
    let(:movement_type) { :debit }

    let(:account) do
      build(:account_definition, name: :cash, type: :asset, currency: :usd)
    end

    def perform
      entry.add_movement(
        movement_type: movement_type, account: account, accountable: accountable
      )
    end

    it { expect { perform }.to change { entry.movements.count }.from(0).to(1) }
    it { expect(perform.account_name).to eq(:cash) }
    it { expect(perform.accountable).to eq(:user) }
    it { expect(perform.account_currency).to eq(:usd) }
    it { expect(perform.movement_type).to eq(movement_type) }

    context "with added movement" do
      before { perform }

      it { expect { perform }.to raise_error(/cash, usd currency and accountable user already/) }

      context "with same account but different currency" do
        let(:another_account) do
          build(:account_definition, name: account.name, type: account.type, currency: :clp)
        end

        it do
          expect do
            entry.add_movement(
              movement_type: movement_type, account: another_account, accountable: accountable
            )
          end.to change { entry.movements.count }.from(1).to(2)
        end
      end
    end

    context "with invalid accountable" do
      let(:accountable) { :invalid }

      it { expect { perform }.to raise_error(/accountable must be a snake_case/) }
    end
  end
end
