FactoryBot.define do
  factory :ledgerizer_entry, class: 'Ledgerizer::Entry' do
    tenant { create(:portfolio) }
    document { create(:deposit) }
    code { :deposit }
    sequence(:entry_time) { |n| DateTime.current + n.seconds }
  end
end
