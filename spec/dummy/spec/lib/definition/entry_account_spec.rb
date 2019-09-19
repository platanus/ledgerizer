require "spec_helper"

RSpec.describe Ledgerizer::Definition::EntryAccount do
  subject(:entry_account) do
    described_class.new(
      account: account,
      accountable: accountable,
      movement_type: movement_type
    )
  end

  let(:account) { Ledgerizer::Definition::Account.new(:cash, :asset) }
  let(:accountable) { "user" }
  let(:movement_type) { "debit" }

  it { expect(entry_account.account).to eq(account) }
  it { expect(entry_account.account_name).to eq(:cash) }
  it { expect(entry_account.accountable).to eq(:user) }
  it { expect(entry_account.movement_type).to eq(:debit) }
  it { expect(entry_account.debit?).to eq(true) }
  it { expect(entry_account.credit?).to eq(false) }

  context "with invalid accountable" do
    let(:accountable) { :invalid }

    it { expect { entry_account }.to raise_error(/must be an ActiveRecord model name/) }
  end
end
