require 'rails_helper'

describe Company do
  it_behaves_like "ledgerizer tenant", :company
  it_behaves_like "ledgerizable entity", :client
  it_behaves_like "ledgerizer lines related", :company
end
