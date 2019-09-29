FactoryBot.define do
  factory :ledgerizer_entry, class: 'Ledgerizer::Entry' do
    association :tenant, factory: :portfolio
    association :document, factory: :portfolio
    code { :deposit }
    entry_date { "1984-06-06" }
  end
end
