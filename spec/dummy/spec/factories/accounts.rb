FactoryBot.define do
  factory :ledgerizer_account, class: 'Ledgerizer::Account' do
    tenant { create(:portfolio) }
    accountable { create(:user) }
    name { :cash }
    account_type { :asset }
    currency { 'CLP' }
  end
end
