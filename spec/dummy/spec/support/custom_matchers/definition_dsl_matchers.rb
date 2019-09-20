RSpec::Matchers.define :have_tenant do |model_class_name|
  match do |dsl_holder|
    dsl_holder&.definition&.find_tenant(model_class_name)&.model_class_name == model_class_name
  end

  description do
    "include #{model_class_name} tenant"
  end

  failure_message do |dsl_holder|
    "#{dsl_holder} does not include #{model_class_name} tenant"
  end
end

RSpec::Matchers.define :have_tenant_base_currency do |model_class_name, expected_currency|
  match do |dsl_holder|
    dsl_holder&.definition&.find_tenant(model_class_name)&.currency == expected_currency
  end

  description do
    "include #{expected_currency} in #{model_class_name} tenant"
  end

  failure_message do
    "#{expected_currency} is not the tenant's currency"
  end
end

RSpec::Matchers.define :have_tenant_account do
  |model_class_name, account_name, account_type, contra = false|
  match do |dsl_holder|
    account = dsl_holder&.definition&.find_tenant(model_class_name)&.find_account(account_name)
    account && account.type == account_type &&
      account.name == account_name &&
      account.contra == contra
  end

  description do
    "include #{account_type} in #{model_class_name} with name #{account_name}"
  end

  failure_message do
    "#{account_type} named #{account_name} is not in tenant"
  end
end

RSpec::Matchers.define :have_tenant_entry do |tenant_class, code, document|
  match do |dsl_holder|
    entry = dsl_holder&.definition&.find_tenant(tenant_class)&.find_entry(code)
    entry && entry.document == document && entry.code == code
  end

  description do
    "include #{code} entry in #{tenant_class} tenant with #{document} document"
  end

  failure_message do
    "#{code} entry is not in tenant"
  end
end

RSpec::Matchers.define :have_tenant_account_entry do |tenant_class, entry_code, expected|
  match do |dsl_holder|
    entry = dsl_holder&.definition&.find_tenant(tenant_class)&.find_entry(entry_code)
    entry&.find_movement(
      movement_type: expected[:movement_type],
      account_name: expected[:account],
      accountable: expected[:accountable]
    )
  end

  description do
    "include #{expected} in #{entry_code} entry of #{tenant_class} tenant"
  end

  failure_message do
    "#{expected} entry is not in #{entry_code} entry of #{tenant_class} tenant"
  end
end
