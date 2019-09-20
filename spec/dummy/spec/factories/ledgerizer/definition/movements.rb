FactoryBot.define do
  factory :movement_definition, class: "Ledgerizer::Definition::Movement" do
    accountable { create(:user) }
    movement_type { :debit }

    transient do
      account_def { {} }
    end

    account do
      FactoryBot.build(:account_definition, account_def)
    end

    skip_create
    initialize_with { new(attributes) }
  end
end
