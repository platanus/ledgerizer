require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
  subject(:executor) do
    described_class.new(
      tenant: tenant,
      document: document,
      entry_code: entry_code,
      entry_date: entry_date
    )
  end

  let(:tenant) { create(:portfolio) }
  let(:document) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  describe '#initialize' do
    define_test_class do
      include Ledgerizer::Definition::Dsl

      tenant(:portfolio, currency: :clp) do
        asset(:cash)

        entry(:deposit, document: :user) do
          credit(account: :cash, accountable: :user)
        end
      end
    end

    it { expect(executor.executable_entry).to be_a(Ledgerizer::Execution::Entry) }
  end

  it_behaves_like 'add executor entry account', :credit
  it_behaves_like 'add executor entry account', :debit
end
