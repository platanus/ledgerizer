require "spec_helper"

describe Ledgerizer::Execution::Account do
  subject(:execution_account) do
    build(
      :executable_account,
      tenant: tenant_instance,
      accountable: accountable_instance,
      account_name: account_name,
      currency: currency
    )
  end

  let(:tenant_instance) { create(:portfolio) }
  let(:accountable_instance) { create(:user) }
  let(:account_name) { :cash }
  let(:currency) { "CLP" }

  describe "#to_array" do
    let(:expected) do
      [
        "Portfolio",
        tenant_instance.id,
        "User",
        accountable_instance.id,
        "cash",
        "CLP"
      ]
    end

    def perform
      execution_account.to_array
    end

    it { expect(perform).to eq(expected) }
  end

  describe "#==" do
    let(:other_tenant_instance) { tenant_instance }
    let(:other_accountable_instance) { accountable_instance }
    let(:other_account_name) { account_name }
    let(:other_currency) { currency }

    let(:other_account) do
      build(
        :executable_account,
        tenant: other_tenant_instance,
        accountable: other_accountable_instance,
        account_name: other_account_name,
        currency: other_currency
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
  end
end
