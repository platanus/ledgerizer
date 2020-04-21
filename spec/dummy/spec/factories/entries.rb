FactoryBot.define do
  factory :ledgerizer_entry, class: 'Ledgerizer::Entry' do
    association :tenant, factory: :portfolio
    association :document, factory: :portfolio
    code { :deposit }
    sequence(:entry_time) { |n| DateTime.current + n.seconds }
  end
end
