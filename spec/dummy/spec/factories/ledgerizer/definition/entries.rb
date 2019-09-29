FactoryBot.define do
  factory :entry_definition, class: "Ledgerizer::Definition::Entry" do
    code { :deposit }
    document { :user }

    skip_create
    initialize_with { new(attributes) }
  end
end
