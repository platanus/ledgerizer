module Ledgerizer
  class EntryExecutor
    include Ledgerizer::Validators
    include Ledgerizer::Formatters

    def initialize(tenant:, document:, entry_code:, entry_date:)
      validate_tenant_instance!(tenant, "tenant")
      @tenant = tenant
      validate_active_record_instance!(document, "document")
      @document = document
      code = format_to_symbol_identifier(entry_code)
      validate_tenant_entry!(tenant, code, document)
      @entry_code = code
      validate_date!(entry_date)
      @entry_date = entry_date.to_date
    end
  end
end
