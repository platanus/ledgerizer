FactoryBot.define do
  factory :account_definition, class: "Ledgerizer::Definition::Account" do
    name { :bank }
    type { :asset }
    currency { :clp }
    mirror_currency { nil }
    contra { false }

    skip_create
    initialize_with { new(attributes) }
  end
end
