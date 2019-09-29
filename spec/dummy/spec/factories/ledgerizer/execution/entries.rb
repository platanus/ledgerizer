FactoryBot.define do
  factory :executable_entry, class: "Ledgerizer::Execution::Entry" do
    document { create(:user) }
    entry_date { "1984-06-04".to_date }

    transient do
      entry_def { {} }
    end

    entry_definition do
      FactoryBot.build(:entry_definition, entry_def)
    end

    skip_create
    initialize_with { new(attributes) }
  end
end
