FactoryBot.define do
  factory :executable_account, class: "Ledgerizer::Execution::Account" do
    account_name { :cash }
    currency { "CLP" }
    mirror_currency { nil }

    transient do
      tenant { create(:portfolio) }
      accountable { create(:user) }
    end

    skip_create

    initialize_with do
      attrs = attributes

      if tenant
        attrs[:tenant_id] = tenant.id
        attrs[:tenant_type] = tenant.class.to_s
      end

      if accountable
        attrs[:accountable_id] = accountable&.id
        attrs[:accountable_type] = accountable.class.to_s
      else
        attrs[:accountable_id] = nil
        attrs[:accountable_type] = nil
      end

      new(attrs)
    end
  end
end
