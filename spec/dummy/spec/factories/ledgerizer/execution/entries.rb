FactoryBot.define do
  factory :executable_entry, class: "Ledgerizer::Execution::Entry" do
    document { create(:user) }
    sequence(:entry_time) { |n| DateTime.current + n.seconds }
    tenant { create(:portfolio) }
    entry_code { :deposit }

    skip_create
    initialize_with { new(attributes) }
  end
end
