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
        currency: "USD",
        mirror_currency: "CLP",
        contra: "1"
      }
    )
  end

  it { expect(movement.account_name).to eq(:cash) }
  it { expect(movement.accountable).to eq(:user) }
  it { expect(movement.accountable_class).to eq(User) }
  it { expect(movement.movement_type).to eq(:debit) }
  it { expect(movement.account_currency).to eq(:usd) }
  it { expect(movement.contra).to eq(true) }
  it { expect(movement.debit?).to eq(true) }
  it { expect(movement.credit?).to eq(false) }
  it { expect(movement.mirror_currency).to eq(:clp) }
end
