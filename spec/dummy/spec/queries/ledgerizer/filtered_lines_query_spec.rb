require "spec_helper"

describe Ledgerizer::FilteredLinesQuery do
  let(:relation) { nil }
  let(:filters) { nil }

  def perform
    described_class.new(relation: relation, filters: filters).all.count
  end

  it { expect(perform).to eq(0) }

  it_behaves_like "filtered lines by attribute", "bank", :force_account_name, :account_name
  it_behaves_like "filtered lines by attribute", "withdrawal", :force_entry_code, :entry_code
  it_behaves_like "filtered lines by attribute", "income", :force_account_type, :account_type

  it_behaves_like "filtered lines by polym_attr", :withdrawal, :force_document, :document
  it_behaves_like "filtered lines by polym_attr", :deposit, :force_document, :document
  it_behaves_like "filtered lines by polym_attr", :client, :force_accountable, :accountable

  it_behaves_like "filtered lines by AR collection", :ledgerizer_entry, :entry, :entries
  it_behaves_like "filtered lines by AR collection", :ledgerizer_account, :account, :accounts

  it_behaves_like "filtered lines by syms collection", :force_entry_code, :entry_code
  it_behaves_like "filtered lines by syms collection", :force_account_type, :account_type
  it_behaves_like "filtered lines by syms collection", :force_account_name, :account_name

  it_behaves_like "filtered lines by predicated attribute",
    :amount, :amount, Money.from_amount(10, 'CLP')
  it_behaves_like "filtered lines by predicated attribute",
    :force_entry_time, :entry_time, Date.current
end
