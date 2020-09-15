FactoryBot.define do
  factory :ledgerizer_entry, class: 'Ledgerizer::Entry' do
    tenant { create(:portfolio) }
    document { create(:deposit) }
    code { :deposit }
    sequence(:entry_time) { |n| DateTime.current + n.seconds }
    mirror_currency { nil }

    trait :mirror_currency do
      mirror_currency { "BTC" }
      conversion_amount { clp(10) }
    end
  end
end
