module Ledgerizer
  class Line < ApplicationRecord
    belongs_to :tenant, polymorphic: true
    belongs_to :document, polymorphic: true
    belongs_to :account
    belongs_to :entry

    monetize :amount_cents

    validates :entry_code, :entry_date, presence: true
  end
end

# == Schema Information
#
# Table name: ledgerizer_lines
#
#  id              :integer          not null, primary key
#  tenant_type     :string
#  tenant_id       :integer
#  document_type   :string
#  document_id     :integer
#  entry_id        :integer
#  account_id      :integer
#  amount_cents    :bigint           default(0), not null
#  amount_currency :string           default("CLP"), not null
#  entry_date      :date
#  entry_code      :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_ledgerizer_lines_on_account_id                     (account_id)
#  index_ledgerizer_lines_on_document_type_and_document_id  (document_type,document_id)
#  index_ledgerizer_lines_on_entry_id                       (entry_id)
#  index_ledgerizer_lines_on_tenant_type_and_tenant_id      (tenant_type,tenant_id)
#
