require 'rails_helper'

RSpec.describe User, type: :model do
  it_behaves_like "ledgerizer active record accountable", :user
end
