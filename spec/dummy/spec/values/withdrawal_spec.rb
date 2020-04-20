require 'rails_helper'

describe Withdrawal do
  it_behaves_like "ledgerizer PORO document", :withdrawal
end
