require "spec_helper"

RSpec.describe Ledgerizer::Definition::Movement do
  subject(:movement) do
    described_class.new(
      account: account,
      accountable: accountable,
      movement_type: movement_type
    )
  end

  let(:accountable) { "user" }
  let(:movement_type) { "debit" }
  let(:base_currency) { "usd" }
  let(:contra) { "1" }

  let(:account) do
    Ledgerizer::Definition::Account.new(
      name: :cash, type: :asset, base_currency: base_currency, contra: contra
    )
  end

  it { expect(movement.account).to eq(account) }
  it { expect(movement.account_name).to eq(:cash) }
  it { expect(movement.accountable).to eq(:user) }
  it { expect(movement.movement_type).to eq(:debit) }
  it { expect(movement.base_currency).to eq(:usd) }
  it { expect(movement.contra).to eq(true) }
  it { expect(movement.debit?).to eq(true) }
  it { expect(movement.credit?).to eq(false) }
end
