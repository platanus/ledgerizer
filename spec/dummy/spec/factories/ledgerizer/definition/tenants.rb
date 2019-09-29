FactoryBot.define do
  factory :tenant_definition, class: "Ledgerizer::Definition::Tenant" do
    model_name { :portfolio }
    currency { :clp }

    skip_create
    initialize_with { new(attributes) }
  end
end
