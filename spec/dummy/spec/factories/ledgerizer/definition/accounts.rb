FactoryBot.define do
  factory :account_definition, class: "Ledgerizer::Definition::Account" do
    name { :bank }
    type { :asset }
    base_currency { :clp }
    contra { false }

    skip_create
    initialize_with { new(attributes) }
  end
end
