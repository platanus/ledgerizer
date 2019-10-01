class Deposit < ApplicationRecord
  include LedgerizerDocument
end

# == Schema Information
#
# Table name: deposits
#
#  id          :integer          not null, primary key
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
