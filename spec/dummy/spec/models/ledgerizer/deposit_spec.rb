require 'rails_helper'

RSpec.describe Deposit, type: :model do
  it_behaves_like "ledgerizer active record document", :deposit
end
