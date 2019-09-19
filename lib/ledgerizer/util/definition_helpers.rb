module Ledgerizer
  module DefinitionHelpers
    def tenant_definition(tenant)
      Ledgerizer.definition.find_tenant(tenant)
    end

    def entry_definition(tenant, entry_code)
      tenant_definition(tenant).find_entry(entry_code)
    end

    def entry_account_definition(tenant, entry_code, movement_type, account_name, accountable)
      entry_definition(tenant, entry_code).send("find_#{movement_type}", account_name, accountable)
    end

    def account_definition(tenant, account_name)
      tenant_definition(tenant).find_account(account_name)
    end
  end
end
