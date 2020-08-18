module Ledgerizer
  class Line < ApplicationRecord
    extend Ledgerizer::Formatters
    include LedgerizerTablePrint
    include PolymorphicAttrs

    polymorphic_attr :tenant
    polymorphic_attr :document
    polymorphic_attr :accountable

    belongs_to :account
    belongs_to :entry

    monetize :amount_cents
    monetize :balance_cents

    validates :amount_cents, :balance_cents, presence: true

    before_save :denormalize_attributes

    scope :sorted, -> { order(entry_time: :desc, id: :desc) }

    def self.filtered(filters = {})
      Ledgerizer::FilteredLinesQuery.new(relation: self, filters: filters).all
    end

    def self.amounts_sum(currency)
      formatted_currency = format_currency(currency, strategy: :upcase, use_default: false)
      return 0 if formatted_currency.blank?

      total = where(amount_currency: formatted_currency).sum(:amount_cents)
      Money.new(total, formatted_currency)
    end

    private

    def denormalize_attributes
      self.tenant_id = entry.tenant_id
      self.tenant_type = entry.tenant_type
      self.document_id = entry.document_id
      self.document_type = entry.document_type
      self.entry_code = entry.code
      self.entry_time = entry.entry_time
      self.accountable_id = account.accountable_id
      self.accountable_type = account.accountable_type
      self.account_name = account.name
      self.account_type = account.account_type
    end
  end
end

# == Schema Information
#
# Table name: ledgerizer_lines
#
#  id               :bigint(8)        not null, primary key
#  tenant_type      :string
#  tenant_id        :bigint(8)
#  entry_id         :bigint(8)
#  entry_time       :datetime
#  entry_code       :string
#  account_type     :string
#  document_type    :string
#  document_id      :bigint(8)
#  account_id       :bigint(8)
#  accountable_type :string
#  accountable_id   :bigint(8)
#  account_name     :string
#  amount_cents     :bigint(8)        default(0), not null
#  amount_currency  :string           default("CLP"), not null
#  balance_cents    :bigint(8)        default(0), not null
#  balance_currency :string           default("CLP"), not null
#
# Indexes
#
#  index_ledgerizer_lines_on_account_id                           (account_id)
#  index_ledgerizer_lines_on_accountable_type_and_accountable_id  (accountable_type,accountable_id)
#  index_ledgerizer_lines_on_document_type_and_document_id        (document_type,document_id)
#  index_ledgerizer_lines_on_entry_id                             (entry_id)
#  index_ledgerizer_lines_on_tenant_type_and_tenant_id            (tenant_type,tenant_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => ledgerizer_accounts.id)
#  fk_rails_...  (entry_id => ledgerizer_entries.id)
#
