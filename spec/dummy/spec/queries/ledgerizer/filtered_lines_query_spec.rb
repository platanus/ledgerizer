require "spec_helper"

describe Ledgerizer::FilteredLinesQuery do
  let(:relation) { nil }
  let(:filters) { nil }

  def perform
    described_class.new(relation: relation, filters: filters).all.count
  end

  it { expect(perform).to eq(0) }

  it_behaves_like "filtered lines by AR collection", :portfolio, :force_tenant, :tenants
  it_behaves_like "filtered lines by AR collection", :ledgerizer_entry, :entry, :entries
  it_behaves_like "filtered lines by AR collection", :ledgerizer_account, :account, :accounts
  it_behaves_like "filtered lines by AR collection", :user, :force_document, :documents
  it_behaves_like "filtered lines by AR collection", :user, :force_accountable, :accountables
  it_behaves_like "filtered lines by syms collection", :force_entry_code, :entry_code
  it_behaves_like "filtered lines by syms collection", :force_account_type, :account_type
  it_behaves_like "filtered lines by syms collection", :force_account_name, :account_name
  it_behaves_like "filtered lines by predicated attribute",
                  :amount, :amount, Money.from_amount(10, 'CLP')
  it_behaves_like "filtered lines by predicated attribute",
                  :force_entry_time, :entry_time, Date.current
end
