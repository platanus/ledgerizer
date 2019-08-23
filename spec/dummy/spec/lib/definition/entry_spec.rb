require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Account do
  subject(:account) { described_class.new(account_name, account_type) }

  let(:account_name) { :cash }
  let(:account_type) { :asset }

  it { expect(account.name).to eq(account_name) }
  it { expect(account.type).to eq(account_type) }
end
# rubocop:enable RSpec/FilePath
