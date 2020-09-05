require "spec_helper"

describe Ledgerizer::Execution::Account do
  subject(:execution_account) do
    build(
      :executable_account,
      tenant: tenant_instance,
      accountable: accountable_instance,
      account_name: account_name,
      account_type: account_type,
      currency: currency,
      mirror_currency: mirror_currency
    )
  end

  let(:tenant_instance) { create(:portfolio) }
  let(:tenant_id) { tenant_instance.id }
  let(:tenant_type) { tenant_instance.class.to_s }
  let(:accountable_instance) { create(:user) }
  let(:accountable_id) { accountable_instance.id }
  let(:accountable_type) { accountable_instance.class.to_s }
  let(:account_name) { :cash }
  let(:account_type) { :asset }
  let(:currency) { "CLP" }
  let(:mirror_currency) { "USD" }

  describe "#to_array" do
    let(:expected) do
      [
        tenant_type,
        tenant_id.to_s,
        accountable_type,
        accountable_id.to_s,
        "asset",
        "cash",
        "CLP",
        mirror_currency.to_s
      ]
    end

    def perform
      execution_account.to_array
    end

    it { expect(perform).to eq(expected) }
  end

  describe "#identifier" do
    let(:expected) do
      "Portfolio::#{tenant_instance.id}::User::#{accountable_instance.id}::asset::cash::CLP::USD"
    end

    def perform
      execution_account.identifier
    end

    it { expect(perform).to eq(expected) }

    context "with nil values" do
      let(:mirror_currency) { nil }
      let(:accountable_instance) { nil }

      let(:expected) do
        "Portfolio::#{tenant_instance.id}::::::asset::cash::CLP::"
      end

      it { expect(perform).to eq(expected) }
    end
  end

  describe "#to_hash" do
    let(:expected) do
      {
        tenant_id: tenant_id,
        tenant_type: tenant_type,
        accountable_id: accountable_id,
        accountable_type: accountable_type,
        account_type: account_type,
        name: account_name,
        currency: currency,
        mirror_currency: mirror_currency
      }
    end

    def perform
      execution_account.to_hash
    end

    it { expect(perform).to eq(expected) }
  end

  describe "#==" do
    let(:other_tenant_instance) { tenant_instance }
    let(:other_accountable_instance) { accountable_instance }
    let(:other_account_name) { account_name }
    let(:other_account_type) { account_type }
    let(:other_currency) { currency }
    let(:other_mirror_currency) { mirror_currency }

    let(:other_account) do
      build(
        :executable_account,
        tenant: other_tenant_instance,
        accountable: other_accountable_instance,
        account_name: other_account_name,
        account_type: other_account_type,
        currency: other_currency,
        mirror_currency: other_mirror_currency
      )
    end

    it { expect(execution_account).to eq(other_account) }

    context "when different tenant" do
      let(:other_tenant_instance) { create(:portfolio) }

      it { expect(execution_account).not_to eq(other_account) }
    end

    context "when different accountable" do
      let(:other_accountable_instance) { create(:user) }

      it { expect(execution_account).not_to eq(other_account) }
    end

    context "when different account_name" do
      let(:other_account_name) { :bank }

      it { expect(execution_account).not_to eq(other_account) }
    end

    context "when different currency" do
      let(:other_currency) { "USD" }

      it { expect(execution_account).not_to eq(other_account) }
    end

    context "when different mirror currency" do
      let(:other_currency) { "BTC" }

      it { expect(execution_account).not_to eq(other_account) }
    end
  end

  describe "#balance" do
    let(:params) do
      {
        tenant_id: tenant_id,
        tenant_type: tenant_type,
        accountable_id: accountable_id,
        accountable_type: accountable_type,
        account_type: account_type,
        account_name: account_name,
        account_mirror_currency: mirror_currency
      }
    end

    let(:sum) { clp(10) }

    let(:lines) do
      class_double("Ledgerizer::Line")
    end

    def perform
      execution_account.balance
    end

    it "calls lines amounts_sum method with valid params" do
      expect(Ledgerizer::Line).to receive(:where).with(params).and_return(lines)
      expect(lines).to receive(:amounts_sum).with(currency).and_return(sum)
      expect(perform).to eq(sum)
    end
  end
end
