require "spec_helper"

RSpec.describe Ledgerizer::Definition::Movement do
  subject(:movement) do
    build(
      :movement_definition,
      accountable: "user",
      movement_type: "debit",
      account_def: {
        name: :cash,
        type: :asset,
        base_currency: "USD",
        contra: "1"
      }
    )
  end

  it { expect(movement.account_name).to eq(:cash) }
  it { expect(movement.accountable).to eq(:user) }
  it { expect(movement.accountable_class).to eq(User) }
  it { expect(movement.movement_type).to eq(:debit) }
  it { expect(movement.base_currency).to eq(:usd) }
  it { expect(movement.contra).to eq(true) }
  it { expect(movement.debit?).to eq(true) }
  it { expect(movement.credit?).to eq(false) }
end
