FactoryBot.define do
  factory :client, class: "Client" do
    skip_create
    initialize_with { new }
  end
end
