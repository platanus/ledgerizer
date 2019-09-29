module LedgerizerAccountable
  extend ActiveSupport::Concern

  ACCOUNT_BALANCE_METHOD_REG_EXP = /\A(ledger)_([^\-]*)_(account)_(balance|lines)\z/
  ACCOUNT_BALANCE_METHOD_PARTS = 4

  included do
    has_many :ledgerizer_accounts,
             as: :accountable,
             class_name: "Ledgerizer::Account",
             dependent: :destroy

    def method_missing(method_name, *arguments, &block)
      if method_config = get_account_method_config(method_name)
        if method_config[:action] == :balance
          return ledger_account_balance_for(method_config[:account_name], *arguments)
        else
          return ledger_account_lines_for(method_config[:account_name], *arguments)
        end
      end

      super
    end

    def respond_to_missing?(method_name, include_private = false)
      get_account_method_config(method_name) || super
    end

    def ledger_account_balance_for(account_name, filters = {})
      lines = ledger_account_lines_for(account_name, filters)
      currency = Ledgerizer.definition.get_tenant_currency(filters[:tenant])
      Money.new(lines.sum(:amount_cents), currency)
    end

    def ledger_account_lines_for(account_name, filters = {})
      filters[:account_name] = account_name
      filters[:accountable] = self
      Ledgerizer::FilteredLinesQuery.new(
        filters: filters,
        permissions: {
          tenant: :required,
          tenants: :forbidden,
          account_names: :forbidden,
          accountables: :forbidden,
          account: :forbidden,
          accounts: :forbidden
        }
      ).all
    end

    def get_account_method_config(method_name)
      return unless method_parts = ledger_account_method_parts(method_name)
      return unless method_parts[0] == 'ledger'
      return unless method_parts[2] == 'account'
      return unless [:lines, :balance].include?(action = method_parts[3].to_sym)
      return unless Ledgerizer.definition.include_account?(account_name = method_parts[1])

      { account_name: account_name, action: action }
    end

    def ledger_account_method_parts(method_name)
      method_parts = method_name.to_s.match(ACCOUNT_BALANCE_METHOD_REG_EXP)&.captures || []
      return if method_parts.count != ACCOUNT_BALANCE_METHOD_PARTS

      method_parts
    end
  end
end
