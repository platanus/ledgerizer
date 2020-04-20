require 'rails_helper'

describe Company do
  it_behaves_like "ledgerizer PORO tenant", :company
  it_behaves_like "ledgerizer tenant", :company
  it_behaves_like "ledgerizer lines related", :company
end
