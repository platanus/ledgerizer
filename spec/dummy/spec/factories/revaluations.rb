FactoryBot.define do
  factory :ledgerizer_revaluation, class: 'Ledgerizer::Revaluation' do
    sequence(:revaluation_time) { |n| DateTime.current + n.seconds }
  end
end
