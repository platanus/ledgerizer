module Ledgerizer
  class Entry < ApplicationRecord
    belongs_to :tenant, polymorphic: true
    belongs_to :document, polymorphic: true
    has_many :lines, dependent: :destroy

    validates :code, :entry_date, presence: true
  end
end

# == Schema Information
#
# Table name: ledgerizer_entries
#
#  id            :integer          not null, primary key
#  tenant_type   :string
#  tenant_id     :integer
#  code          :string
#  document_type :string
#  document_id   :integer
#  entry_date    :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_ledgerizer_entries_on_document_type_and_document_id  (document_type,document_id)
#  index_ledgerizer_entries_on_tenant_type_and_tenant_id      (tenant_type,tenant_id)
#
