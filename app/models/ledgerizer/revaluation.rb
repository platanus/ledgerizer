module Ledgerizer
  class Revaluation < ApplicationRecord
    monetize :amount_cents

    validates :amount_cents, :revaluation_time, presence: true
  end
end

# == Schema Information
#
# Table name: ledgerizer_revaluations
#
#  id               :bigint(8)        not null, primary key
#  revaluation_time :datetime
#  amount_cents     :bigint(8)        default(0), not null
#  amount_currency  :string           default("CLP"), not null
#
# Indexes
#
#  unique_revaluations_index  (revaluation_time,amount_currency) UNIQUE
#
