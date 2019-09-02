require "spec_helper"

RSpec.describe Ledgerizer::Definition::EntryAccount do
  subject(:entry_account) { described_class.new(account, accountable) }

  let(:account) { Ledgerizer::Definition::Account.new(:cash, :asset) }
  let(:accountable) { "user" }

  it { expect(entry_account.account).to eq(account) }
  it { expect(entry_account.account_name).to eq(:cash) }
  it { expect(entry_account.accountable).to eq(:user) }

  context "with invalid accountable" do
    let(:accountable) { :invalid }

    it { expect { entry_account }.to raise_error(/must be an ActiveRecord model name/) }
  end
end
