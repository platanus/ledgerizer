FactoryBot.define do
  factory :withdrawal, class: "Withdrawal" do
    skip_create
    initialize_with { new }
  end
end
