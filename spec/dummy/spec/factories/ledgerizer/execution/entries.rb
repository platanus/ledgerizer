FactoryBot.define do
  factory :executable_entry, class: "Ledgerizer::Execution::Entry" do
    document { create(:user) }
    entry_date { "1984-06-04".to_date }
    tenant { create(:portfolio) }
    entry_code { :deposit }

    skip_create
    initialize_with { new(attributes) }
  end
end
