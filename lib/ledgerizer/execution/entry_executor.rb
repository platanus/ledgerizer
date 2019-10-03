module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    delegate :movements, to: :executable_entry, prefix: false

    def initialize(config:, tenant:, document:, entry_code:, entry_date:)
      tenant_definition = get_tenant_definition!(config, tenant)
      @tenant = tenant
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

    def execute
      validate_execution!
      create_entry_lines!
      true
    end

    private

    attr_reader :executable_entry, :tenant

    def create_entry_lines!
      ActiveRecord::Base.transaction do
        entry = create_entry!
        movements.each do |movement|
          account = find_or_create_account!(movement)
          create_line!(entry, account, movement)
        end
      end
    end

    def create_entry!
      Ledgerizer::Entry.create!(
        tenant: tenant,
        code: executable_entry.code,
        document: executable_entry.document,
        entry_date: executable_entry.entry_date
      )
    end

    def create_line!(entry, account, movement)
      entry.lines.create!(
        account: account,
        amount: movement.signed_amount
      )
    end

    def find_or_create_account!(movement)
      Ledgerizer::Account.find_or_create_by!(
        tenant: tenant,
        accountable: movement.accountable,
        name: movement.account_name,
        currency: format_to_upcase(movement.base_currency),
        account_type: movement.account_type
      )
    end

    def get_tenant_definition!(config, tenant)
      validate_active_record_instance!(tenant, "tenant")
      tenant_definition = config.find_tenant(tenant)
      return tenant_definition if tenant_definition

      raise_error("can't find tenant for given #{tenant.model_name} model")
    end

    def get_entry_definition!(tenant_definition, entry_code)
      code = format_to_symbol_identifier(entry_code)
      entry_definition = tenant_definition.find_entry(code)
      return entry_definition if entry_definition

      raise_error("invalid entry code #{entry_code} for given tenant")
    end

    def validate_execution!
      validate_existent_movements!
      validate_zero_trial_balance!
    end

    def validate_existent_movements!
      raise_error("can't execute entry without movements") if movements.none?
    end

    def validate_zero_trial_balance!
      raise_error("trial balance must be zero") unless executable_entry.zero_trial_balance?
    end
  end
end
