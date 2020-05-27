require 'rails_helper'

describe User, type: :model do
  it_behaves_like "ledgerizer accountable", :user
  it_behaves_like "ledgerizable entity", :client
end
