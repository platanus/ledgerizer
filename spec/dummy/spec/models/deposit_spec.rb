require 'rails_helper'

describe Deposit, type: :model do
  it_behaves_like "ledgerizer document", :deposit
  it_behaves_like "ledgerizable entity", :client
end
