class Portfolio < ApplicationRecord
  include LedgerizerTenant
end

# == Schema Information
#
# Table name: portfolios
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
