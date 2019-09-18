require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Account do
  subject(:account) { described_class.new(account_name, account_type) }

  let(:account_name) { :cash }
  let(:account_type) { :asset }

  it { expect(account.name).to eq(account_name) }
  it { expect(account.type).to eq(account_type) }

  context "with string name" do
    let(:account_name) { "cash" }

    it { expect(account.name).to eq(account_name.to_sym) }
  end

  context "with blank name" do
    let(:account_name) { "" }

    it { expect { account }.to raise_error('account name is mandatory') }
  end

  context "with blank type" do
    let(:account_type) { "" }

    it { expect { account }.to raise_error('account type is mandatory') }
  end

  context "with invalid type" do
    let(:account_type) { "Invalid" }

    it { expect { account }.to raise_error(/type must be one of these/) }
  end
end
# rubocop:enable RSpec/FilePath
