require 'rails_helper'

describe Client do
  it_behaves_like "ledgerizer accountable", :client
  it_behaves_like "ledgerizable entity", :client
end
