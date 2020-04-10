module Ledgerizer
  class Account < ApplicationRecord
    extend Enumerize
    include Ledgerizer::Formatters
    include LedgerizerLinesRelated

    belongs_to :tenant, polymorphic: true
    belongs_to :accountable, polymorphic: true, optional: true
    has_many :lines, dependent: :destroy

    enumerize :account_type, in: Ledgerizer::Definition::Account::TYPES,
                             predicates: { prefix: true }

    monetize :balance_cents

    validates :name, :currency, :account_type, :balance_cents, presence: true
    validates :currency, ledgerizer_currency: true

    before_save :load_format_currency

    def forbidden_line_filters
      [
        :tenant, :tenants,
        :account_name, :account_names,
        :accountable, :accountables,
        :account_type, :account_types,
        :account, :accounts
      ]
    end

    def self.find_by_executable_account(executable_account, lock: false)
      accounts = where(executable_account.to_hash)
      accounts = accounts.lock(true) if lock
      accounts.first
    end

    private

    def load_format_currency
      self.currency = format_currency(currency, strategy: :upcase, use_default: false) if currency
    end
  end
end

# == Schema Information
#
# Table name: ledgerizer_accounts
#
#  id               :bigint(8)        not null, primary key
#  tenant_type      :string
#  tenant_id        :bigint(8)
#  accountable_type :string
#  accountable_id   :bigint(8)
#  name             :string
#  currency         :string
#  account_type     :string
#  balance_cents    :bigint(8)        default(0), not null
#  balance_currency :string           default("CLP"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_ledgerizer_accounts_on_acc_type_and_acc_id        (accountable_type,accountable_id)
#  index_ledgerizer_accounts_on_tenant_type_and_tenant_id  (tenant_type,tenant_id)
#  unique_account_index                                    (accountable_type,accountable_id,name,account_type,currency,tenant_id,tenant_type) UNIQUE
#
