FactoryBot.define do
  factory :revaluation_definition, class: "Ledgerizer::Definition::Revaluation" do
    name { :crypto_exposure }

    skip_create
    initialize_with { new(attributes) }
  end
end
