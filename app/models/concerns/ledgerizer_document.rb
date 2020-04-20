module LedgerizerDocument
  extend ActiveSupport::Concern

  included do
    if ancestors.include?(ActiveRecord::Base)
      include AR::LedgerizerDocument
    else
      include PORO::LedgerizerDocument
    end
  end
end
