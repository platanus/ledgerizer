module Ledgerizer
  class Entry < ApplicationRecord
    include Ledgerizer::Formatters
    include LedgerizerLinesRelated
    include LedgerizerTablePrint
    include PolymorphicAttrs

    polymorphic_attr :tenant
    polymorphic_attr :document

    has_many :lines, -> { sorted }, dependent: :destroy, inverse_of: :entry
    has_many :accounts, through: :lines

    validates :mirror_currency, ledgerizer_currency: true
    validates :code, :tenant_type, :tenant_id, :document_type, :document_id,
      :entry_time, presence: true

    before_save :load_formatted_mirror_currency

    delegate :currency, to: :tenant, prefix: false # TODO: denormalize

    monetize :conversion_amount_cents, allow_nil: true, numericality: { greater_than: 0.0 }

    def mirror_currency?
      mirror_currency.present?
    end

    def forbidden_line_filters
      [
        :tenant, :tenants,
        :entry, :entries,
        :entry_code, :entry_codes,
        :entry_time, :entry_times,
        :document, :documents,
        :account_mirror_currency, :amount_currency
      ]
    end

    private

    def load_formatted_mirror_currency
      if mirror_currency
        self.mirror_currency = format_currency(
          mirror_currency,
          strategy: :upcase,
          use_default: false
        )
      end
    end
  end
end

# == Schema Information
#
# Table name: ledgerizer_entries
#
#  id                         :bigint(8)        not null, primary key
#  tenant_type                :string
#  tenant_id                  :bigint(8)
#  code                       :string
#  document_type              :string
#  document_id                :bigint(8)
#  entry_time                 :datetime
#  mirror_currency            :string
#  conversion_amount_cents    :bigint(8)
#  conversion_amount_currency :string           default("CLP"), not null
#
# Indexes
#
#  index_ledgerizer_entries_on_document_type_and_document_id  (document_type,document_id)
#  index_ledgerizer_entries_on_tenant_type_and_tenant_id      (tenant_type,tenant_id)
#  unique_entry_index                                         (tenant_id,tenant_type,document_id,document_type,code,mirror_currency) UNIQUE
#
