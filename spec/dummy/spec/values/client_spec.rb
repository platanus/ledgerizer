require 'rails_helper'

describe Client do
  it_behaves_like "ledgerizer PORO accountable", :client
end
