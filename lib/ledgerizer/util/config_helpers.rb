module Ledgerizer
  module ConfigHelpers
    def tenant_conf(tenant_identifier)
      Ledgerizer.definition.find_tenant(tenant_identifier)
    end

    def entry_conf(tenant_identifier, entry_code)
      tenant_conf(tenant_identifier).find_entry(entry_code)
    end

    def entry_account_conf(tenant, entry_code, mov_type, account_name, accountable)
      entry_conf(tenant, entry_code).send("find_#{mov_type}", account_name, accountable)
    end

    def account_conf(tenant_identifier, account_name)
      tenant_conf(tenant_identifier).find_account(account_name)
    end
  end
end
