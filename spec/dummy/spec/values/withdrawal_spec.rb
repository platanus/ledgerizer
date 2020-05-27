require 'rails_helper'

describe Withdrawal do
  it_behaves_like "ledgerizer document", :withdrawal
  it_behaves_like "ledgerizable entity", :client
end
