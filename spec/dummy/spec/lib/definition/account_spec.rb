require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Entry do
  subject(:entry) { described_class.new(code, document) }

  let(:code) { :cash }
  let(:document) { Portfolio }

  it { expect(entry.code).to eq(code) }
  it { expect(entry.document).to eq(document) }
end
# rubocop:enable RSpec/FilePath
