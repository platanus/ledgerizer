FactoryBot.define do
  factory :ledgerizer_account, class: 'Ledgerizer::Account' do
    association :tenant, factory: :portfolio
    association :accountable, factory: :user
    name { :cash }
    account_type { :asset }
    currency { 'CLP' }
  end
end
