require "spec_helper"

describe Ledgerizer::Definition::Revaluation do
  subject(:account) do
    build(
      :revaluation_definition,
      name: name
    )
  end

  let(:name) { :crypto_exposure }

  it { expect(account.name).to eq(:crypto_exposure) }
  it { expect(account.income_revaluation_account).to eq(:positive_crypto_exposure) }
  it { expect(account.expense_revaluation_account).to eq(:negative_crypto_exposure) }

  context "with string name" do
    let(:name) { "crypto_exposure" }

    it { expect(account.name).to eq(:crypto_exposure) }
    it { expect(account.income_revaluation_account).to eq(:positive_crypto_exposure) }
    it { expect(account.expense_revaluation_account).to eq(:negative_crypto_exposure) }
  end

  context "with uppcase name" do
    let(:name) { "CRYPTO_EXPOSURE" }

    it { expect(account.name).to eq(:crypto_exposure) }
    it { expect(account.income_revaluation_account).to eq(:positive_crypto_exposure) }
    it { expect(account.expense_revaluation_account).to eq(:negative_crypto_exposure) }
  end

  describe "add_account" do
    let(:accountable) { "user" }
    let(:account_name) { "deposit" }

    def perform
      account.add_account(
        account_name: account_name, accountable: accountable
      )
    end

    it { expect { perform }.to change { account.accounts.count }.from(0).to(1) }
    it { expect(perform.name).to eq(:deposit) }
    it { expect(perform.accountable).to eq(:user) }

    context "with blank accountable" do
      let(:accountable) { "" }

      it { expect { perform }.to change { account.accounts.count }.from(0).to(1) }
      it { expect(perform.name).to eq(:deposit) }
      it { expect(perform.accountable).to be_nil }
    end

    context "with previously added account" do
      before { perform }

      it { expect { perform }.not_to(change { account.accounts.count }) }
    end
  end
end
