RSpec::Matchers.define :have_tenant do |model_class|
  match do |dsl_holder|
    dsl_holder&.definition&.find_tenant(model_class)&.model_class == model_class
  end

  description do
    "include #{model_class} tenant"
  end

  failure_message do |dsl_holder|
    "#{dsl_holder} does not include #{model_class} tenant"
  end
end

RSpec::Matchers.define :have_tenant_base_currency do |model_class, expected_currency|
  match do |dsl_holder|
    dsl_holder&.definition&.find_tenant(model_class)&.currency == expected_currency
  end

  description do
    "include #{expected_currency} in #{model_class} tenant"
  end

  failure_message do
    "#{expected_currency} is not the tenant's currency"
  end
end

RSpec::Matchers.define :have_tenant_account do |model_class, account_name, account_type|
  match do |dsl_holder|
    account = dsl_holder&.definition&.find_tenant(model_class)&.find_account(account_name)
    account && account.type == account_type && account.name == account_name
  end

  description do
    "include #{account_type} in #{model_class} with name #{account_name}"
  end

  failure_message do
    "#{account_type} named #{account_name} is not in tenant"
  end
end
