RSpec::Matchers.define :have_tenant do |model_class|
  match do |dsl_holder|
    dsl_holder.definition.find_tenant(model_class)&.model_class == model_class
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
    dsl_holder.definition.find_tenant(model_class)&.currency == expected_currency
  end

  description do
    "include #{expected_currency} in #{model_class} tenant"
  end

  failure_message do
    "#{expected_currency} is not the tenant's currency"
  end
end
