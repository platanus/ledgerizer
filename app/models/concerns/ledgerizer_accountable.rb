module LedgerizerAccountable
  extend ActiveSupport::Concern

  included do
    if ancestors.include?(ActiveRecord::Base)
      include AR::LedgerizerAccountable
    else
      include PORO::LedgerizerAccountable
    end
  end
end
