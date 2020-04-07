FactoryBot.define do
  factory :executable_account, class: "Ledgerizer::Execution::Account" do
    tenant { create(:portfolio) }
    accountable { create(:user) }
    account_name { :cash }
    currency { "CLP" }

    skip_create
    initialize_with { new(attributes) }
  end
end
