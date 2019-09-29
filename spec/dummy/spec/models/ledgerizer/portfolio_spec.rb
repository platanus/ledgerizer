require 'rails_helper'

RSpec.describe Portfolio, type: :model do
  it_behaves_like "ledgerizer tenant", :portfolio
  it_behaves_like "ledgerizer lines related", :portfolio
end
