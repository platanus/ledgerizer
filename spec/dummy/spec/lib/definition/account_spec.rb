require "spec_helper"

describe Ledgerizer::Definition::Account do
  subject(:account) do
    build(
      :account_definition,
      name: account_name,
      type: account_type,
      currency: currency,
      mirror_currency: mirror_currency,
      contra: contra
    )
  end

  let(:account_name) { :cash }
  let(:account_type) { :asset }
  let(:contra) { true }
  let(:currency) { "USD" }
  let(:mirror_currency) { nil }

  it { expect(account.name).to eq(account_name) }
  it { expect(account.type).to eq(account_type) }
  it { expect(account.contra).to eq(true) }
  it { expect(account.currency).to eq(:usd) }
  it { expect(account.mirror_currency).to be_nil }
  it { expect(account.credit?).to eq(false) }
  it { expect(account.debit?).to eq(true) }

  context "with string name" do
    let(:account_name) { "cash" }

    it { expect(account.name).to eq(account_name.to_sym) }
  end

  context "with blank type" do
    let(:account_type) { "" }

    it { expect { account }.to raise_error(/type must be one of these/) }
  end

  context "with invalid type" do
    let(:account_type) { "Invalid" }

    it { expect { account }.to raise_error(/type must be one of these/) }
  end

  context "with false contra" do
    let(:contra) { false }

    it { expect(account.contra).to eq(false) }
  end

  context "with nil contra" do
    let(:contra) { nil }

    it { expect(account.contra).to eq(false) }
  end

  context "with string contra" do
    let(:contra) { "true" }

    it { expect(account.contra).to eq(true) }
  end

  context "with mirror currency" do
    let(:mirror_currency) { "BTC" }

    it { expect(account.mirror_currency).to eq(:btc) }
  end

  context "with credit account type" do
    let(:account_type) { :liability }

    it { expect(account.credit?).to eq(true) }
    it { expect(account.debit?).to eq(false) }
  end
end
