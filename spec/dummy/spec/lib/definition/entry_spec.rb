require "spec_helper"

# rubocop:disable RSpec/FilePath
RSpec.describe Ledgerizer::Definition::Entry do
  subject(:entry) { described_class.new(code, document) }

  let(:code) { :deposit }
  let(:document) { Portfolio }

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

  it_behaves_like 'add entry account', :debit
  it_behaves_like 'add entry account', :credit
end
# rubocop:enable RSpec/FilePath
