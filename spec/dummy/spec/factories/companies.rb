FactoryBot.define do
  factory :company, class: "Company" do
    skip_create
    initialize_with { new }
  end
end
