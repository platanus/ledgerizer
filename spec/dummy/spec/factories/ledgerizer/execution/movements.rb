FactoryBot.define do
  factory :executable_movement, class: "Ledgerizer::Execution::Movement" do
    accountable { create(:user) }
    amount { clp(1000) }

    transient do
      movement_def { {} }
    end

    movement_definition do
      FactoryBot.build(:movement_definition, movement_def)
    end

    skip_create
    initialize_with { new(attributes) }
  end
end
