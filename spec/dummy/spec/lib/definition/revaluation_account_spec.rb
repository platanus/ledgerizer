require "spec_helper"

describe Ledgerizer::Definition::RevaluationAccount do
  subject(:account) do
    build(
      :revaluation_account_definition,
      name: account_name,
      accountable: accountable
    )
  end

  let(:account_name) { :cash }
  let(:accountable) { :user }

  it { expect(account.name).to eq(account_name) }
  it { expect(account.accountable).to eq(accountable) }

  context "with string name" do
    let(:account_name) { "cash" }

    it { expect(account.name).to eq(:cash) }
  end

  context "with uppcase name" do
    let(:account_name) { "CASH" }

    it { expect(account.name).to eq(:cash) }
  end

  context "with string accountable" do
    let(:accountable) { "user" }

    it { expect(account.accountable).to eq(:user) }
  end

  context "with uppcase accountable" do
    let(:accountable) { "user" }

    it { expect(account.accountable).to eq(:user) }
  end

  context "with blank accountable" do
    let(:accountable) { "" }

    it { expect(account.accountable).to be_nil }
  end
end
