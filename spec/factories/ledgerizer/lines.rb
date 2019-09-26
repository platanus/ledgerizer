FactoryBot.define do
  factory :ledgerizer_line, class: 'Ledgerizer::Line' do
    association :tenant, factory: :portfolio
    association :entry, factory: :ledgerizer_entry
    association :document, factory: :portfolio
    association :account, factory: :ledgerizer_account
    association :accountable, factory: :user
    account_name { :cash }
    entry_code { :deposit }
    entry_date { "1984-06-06" }
  end
end
