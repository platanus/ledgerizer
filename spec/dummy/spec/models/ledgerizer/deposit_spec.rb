require 'rails_helper'

RSpec.describe Deposit, type: :model do
  it_behaves_like "ledgerizer document", :deposit
end
