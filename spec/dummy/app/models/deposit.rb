class Deposit < ApplicationRecord
  include LedgerizerDocument
end

# == Schema Information
#
# Table name: deposits
#
#  id          :bigint(8)        not null, primary key
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
