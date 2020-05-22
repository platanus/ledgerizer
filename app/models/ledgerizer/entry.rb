module Ledgerizer
  class Entry < ApplicationRecord
    include LedgerizerLinesRelated
    include LedgerizerTablePrint
    include PolymorphicAttrs

    polymorphic_attr :tenant
    polymorphic_attr :document

    has_many :lines, -> { sorted }, dependent: :destroy
    has_many :accounts, through: :lines

    validates :code, :tenant_type, :tenant_id, :document_type, :document_id,
      :entry_time, presence: true

    delegate :currency, to: :tenant, prefix: false # TODO: denormalize

    def forbidden_line_filters
      [
        :tenant, :tenants,
        :entry, :entries,
        :entry_code, :entry_codes,
        :entry_time, :entry_times,
        :document, :documents
      ]
    end
  end
end

# == Schema Information
#
# Table name: ledgerizer_entries
#
#  id            :bigint(8)        not null, primary key
#  tenant_type   :string
#  tenant_id     :bigint(8)
#  code          :string
#  document_type :string
#  document_id   :bigint(8)
#  entry_time    :datetime
#
# Indexes
#
#  index_ledgerizer_entries_on_document_type_and_document_id  (document_type,document_id)
#  index_ledgerizer_entries_on_tenant_type_and_tenant_id      (tenant_type,tenant_id)
#  unique_entry_index                                         (tenant_id,tenant_type,document_id,document_type,code) UNIQUE
#
