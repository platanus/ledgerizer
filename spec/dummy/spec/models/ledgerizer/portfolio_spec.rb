require 'rails_helper'

describe Portfolio, type: :model do
  it_behaves_like "ledgerizer active record tenant", :portfolio
  it_behaves_like "ledgerizer tenant", :portfolio
  it_behaves_like "ledgerizer lines related", :portfolio
end
