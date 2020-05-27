FactoryBot.define do
  factory :ledgerizer_line, class: 'Ledgerizer::Line' do
    association :entry, factory: :ledgerizer_entry
    association :account, factory: :ledgerizer_account

    transient do
      force_tenant { nil }
      force_document { nil }
      force_accountable { nil }

      force_account_name { nil }
      force_account_type { nil }
      force_entry_code { nil }
      force_entry_time { nil }
    end

    after :create do |line, evaluator|
      set_polymorphic_relation(line, :tenant, evaluator.force_tenant)
      set_polymorphic_relation(line, :document, evaluator.force_document)
      set_polymorphic_relation(line, :accountable, evaluator.force_accountable)
      set_denormalized_attribute(line, :account_name, evaluator.force_account_name)
      set_denormalized_attribute(line, :account_type, evaluator.force_account_type)
      set_denormalized_attribute(line, :entry_code, evaluator.force_entry_code)
      set_denormalized_attribute(line, :entry_time, evaluator.force_entry_time)
    end
  end
end
