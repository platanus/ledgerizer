FactoryBot.define do
  factory :revaluation_account_definition, class: "Ledgerizer::Definition::RevaluationAccount" do
    name { :bank }
    accountable { :user }

    skip_create
    initialize_with { new(attributes) }
  end
end
