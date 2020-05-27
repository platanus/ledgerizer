module Ledgerizer
  module Execution
    class Entry
      include Ledgerizer::Validators
      include Ledgerizer::Formatters

      attr_reader :document, :entry_time

      delegate :code, to: :entry_definition, prefix: false

      def initialize(config:, tenant:, document:, entry_code:, entry_time:)
        tenant_definition = get_tenant_definition!(config, tenant)
        @tenant = tenant
        @entry_definition = get_entry_definition!(tenant_definition, entry_code)
        validate_entry_document!(document)
        @document = document
        validate_datetime!(entry_time)
        @entry_time = entry_time.to_datetime
      end

      def add_new_movement(movement_type:, account_name:, accountable:, amount:)
        movement_definition = get_movement_definition!(movement_type, account_name, accountable)
        movement = Ledgerizer::Execution::Movement.new(
          movement_definition: movement_definition,
          accountable: accountable,
          amount: amount
        )

        new_movements << movement
        movement
      end

      def entry_instance
        @entry_instance ||= find_or_create_entry_instance
      end

      def new_movements
        @new_movements ||= []
      end

      def related_accounts
        @related_accounts ||= begin
          (accounts_from_new_movements + accounts_from_entry_instance).inject([]) do |memo, account|
            memo << account unless memo.include?(account)
            memo
          end
        end
      end

      private

      attr_reader :entry_definition, :tenant

      def find_or_create_entry_instance
        entry_data = {
          code: code,
          document_id: document.to_id_attr,
          document_type: document.to_type_attr,
          entry_time: entry_time,
          tenant_id: tenant.to_id_attr,
          tenant_type: tenant.to_type_attr
        }
        entry = tenant.entries.find_by(entry_data)
        return entry if entry

        Ledgerizer::Entry.create!(entry_data)
      end

      def accounts_from_new_movements
        new_movements.map do |movement|
          account = Ledgerizer::Execution::Account.new(
            tenant_id: tenant.to_id_attr,
            tenant_type: tenant.to_type_attr,
            accountable_id: movement.accountable&.to_id_attr,
            accountable_type: movement.accountable&.to_type_attr,
            account_name: movement.account_name.to_sym,
            account_type: movement.account_type.to_sym,
            currency: movement.signed_amount_currency.to_s
          )
          movement.account_identifier = account.identifier
          account
        end
      end

      def accounts_from_entry_instance
        entry_instance.accounts.to_a.map do |account|
          Ledgerizer::Execution::Account.new(
            tenant_id: tenant.to_id_attr,
            tenant_type: tenant.to_type_attr,
            accountable_id: account.accountable_id,
            accountable_type: account.accountable_type,
            account_name: account.name.to_sym,
            account_type: get_movement_definition_from_account(account).account_type.to_sym,
            currency: account.balance_currency
          )
        end
      end

      def validate_entry_document!(document)
        validate_ledgerized_instance!(document, "document", LedgerizerDocument)

        if format_ledgerizer_instance_to_sym(document) != entry_definition.document
          raise_error("invalid document #{document.class} for given #{entry_definition.code} entry")
        end
      end

      def get_movement_definition!(movement_type, account_name, accountable)
        if accountable
          validate_ledgerized_instance!(accountable, "accountable", LedgerizerAccountable)
        end

        movement_definition = entry_definition.find_movement(
          movement_type: movement_type,
          account_name: account_name,
          accountable: accountable
        )
        return movement_definition if movement_definition

        raise_error(
          "invalid movement #{account_name} with accountable " +
            "#{accountable.class} for given #{entry_definition.code} " +
            "entry in #{movement_type.to_s.pluralize}"
        )
      end

      def get_movement_definition_from_account(account)
        %i{debit credit}.map do |movement_type|
          entry_definition.find_movement(
            movement_type: movement_type,
            account_name: format_to_symbol_identifier(account.name),
            accountable: format_to_symbol_identifier(account.accountable_type)
          )
        end.compact.first
      end

      def get_tenant_definition!(config, tenant)
        validate_ledgerized_instance!(tenant, "tenant", LedgerizerTenant)
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
    end
  end
end
