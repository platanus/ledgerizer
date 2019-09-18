require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::EntryAccount do
  subject(:entry_account) { described_class.new(account, accountable) }

  let(:account) { Ledgerizer::Definition::Account.new(:cash, :asset) }
  let(:accountable) { "portfolio" }

  it { expect(entry_account.account).to eq(account) }
  it { expect(entry_account.account_name).to eq(:cash) }
  it { expect(entry_account.accountable).to eq(:portfolio) }

  context "with invalid accountable" do
    let(:accountable) { :invalid }

    it { expect { entry_account }.to raise_error(/must be an ActiveRecord model name/) }
  end
end
# rubocop:enable RSpec/FilePath
