module Ledgerizer
  class Line < ApplicationRecord
    extend Ledgerizer::Formatters

    belongs_to :tenant, polymorphic: true, optional: true
    belongs_to :document, polymorphic: true, optional: true
    belongs_to :accountable, polymorphic: true, optional: true
    belongs_to :account
    belongs_to :entry

    monetize :amount_cents
    monetize :balance_cents

    validates :amount_cents, :balance_cents, presence: true

    before_save :denormalize_attributes

    def self.filtered(filters = {})
      Ledgerizer::FilteredLinesQuery.new(relation: self, filters: filters).all
    end

    def self.amounts_sum(currency)
      formatted_currency = format_currency(currency, strategy: :upcase, use_default: false)
      total = where(amount_currency: formatted_currency).sum(:amount_cents)
      Money.new(total, formatted_currency)
    end

    private

    def denormalize_attributes
      self.tenant = entry.tenant
      self.document = entry.document
      self.entry_code = entry.code
      self.entry_date = entry.entry_date
      self.accountable = account.accountable
      self.account_name = account.name
      self.account_type = account.account_type
    end
  end
end

# == Schema Information
#
# Table name: ledgerizer_lines
#
#  id               :integer          not null, primary key
#  tenant_type      :string
#  tenant_id        :integer
#  entry_id         :integer
#  entry_date       :date
#  entry_code       :string
#  account_type     :string
#  document_type    :string
#  document_id      :integer
#  account_id       :integer
#  accountable_type :string
#  accountable_id   :integer
#  account_name     :string
#  amount_cents     :bigint           default(0), not null
#  amount_currency  :string           default("CLP"), not null
#  balance_cents    :bigint           default(0), not null
#  balance_currency :string           default("CLP"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_ledgerizer_lines_on_account_id                           (account_id)
#  index_ledgerizer_lines_on_accountable_type_and_accountable_id  (accountable_type,accountable_id)
#  index_ledgerizer_lines_on_document_type_and_document_id        (document_type,document_id)
#  index_ledgerizer_lines_on_entry_id                             (entry_id)
#  index_ledgerizer_lines_on_tenant_type_and_tenant_id            (tenant_type,tenant_id)
#
