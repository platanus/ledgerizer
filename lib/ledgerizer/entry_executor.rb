module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    def initialize(config:, tenant:, document:, entry_code:, entry_date:)
      tenant_definition = get_tenant_definition!(config, tenant)
      @executable_entry = Ledgerizer::Execution::Entry.new(
        document: document,
        entry_definition: get_entry_definition!(tenant_definition, entry_code),
        entry_date: entry_date
      )
    end

    def add_movement(movement_type:, account_name:, accountable:, amount:)
      executable_entry.add_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable,
        amount: amount
      )
    end

    private

    attr_reader :executable_entry

    def get_tenant_definition!(config, tenant)
      validate_active_record_instance!(tenant, "tenant")
      tenant_definition = config.find_tenant(tenant)
      return tenant_definition if tenant_definition

      raise_validation_error("can't find tenant for given #{tenant.model_name} model")
    end

    def get_entry_definition!(tenant_definition, entry_code)
      code = format_to_symbol_identifier(entry_code)
      entry_definition = tenant_definition.find_entry(code)
      return entry_definition if entry_definition

      raise_validation_error("invalid entry code #{entry_code} for given tenant")
    end
  end
end
