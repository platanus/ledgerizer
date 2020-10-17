module Ledgerizer
  class Revaluation < ApplicationRecord
    include LedgerizerDocument
    include PolymorphicAttrs

    polymorphic_attr :tenant

    monetize :amount_cents

    validates :amount_cents, :revaluation_time, :currency, presence: true
    validates :currency, ledgerizer_currency: true
  end
end

# == Schema Information
#
# Table name: ledgerizer_revaluations
#
#  id               :bigint(8)        not null, primary key
#  tenant_type      :string
#  tenant_id        :bigint(8)
#  currency         :string
#  revaluation_time :datetime
#  amount_cents     :bigint(8)        default(0), not null
#  amount_currency  :string           default("CLP"), not null
#
# Indexes
#
#  index_ledgerizer_revaluations_on_tenant_type_and_tenant_id  (tenant_type,tenant_id)
#  unique_revaluations_index                                   (tenant_id,tenant_type,revaluation_time,currency) UNIQUE
#
