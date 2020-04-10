module Ledgerizer
  class Entry < ApplicationRecord
    include LedgerizerLinesRelated

    belongs_to :tenant, polymorphic: true
    belongs_to :document, polymorphic: true
    has_many :lines, dependent: :destroy

    validates :code, :entry_date, presence: true

    delegate :currency, to: :tenant, prefix: false # TODO: denormalize

    def forbidden_line_filters
      [
        :tenant, :tenants,
        :entry, :entries,
        :entry_code, :entry_codes,
        :entry_date, :entry_dates,
        :document, :documents
      ]
    end

    def create_line!(executable_movement)
      lines.create!(
        account: tenant.find_or_create_account_from_executable_movement!(executable_movement),
        amount_cents: executable_movement.signed_amount_cents,
        amount_currency: executable_movement.signed_amount_currency
      )
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
#  entry_date    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_ledgerizer_entries_on_document_type_and_document_id  (document_type,document_id)
#  index_ledgerizer_entries_on_tenant_type_and_tenant_id      (tenant_type,tenant_id)
#
