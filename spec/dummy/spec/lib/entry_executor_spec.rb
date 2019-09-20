require "spec_helper"

RSpec.describe Ledgerizer::EntryExecutor do
  subject(:executor) do
    described_class.new(
      config: config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code_param,
      entry_date: entry_date
    )
  end

  let(:config) { Ledgerizer::Definition::Config.new }
  let(:tenant_currency) { :clp }
  let(:tenant) { :portfolio }
  let(:tenant_instance) { create(:portfolio) }
  let(:document) { :user }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_code_param) { entry_code }
  let(:entry_date) { "1984-06-04" }
  let!(:tenant_definition) { config.add_tenant(model_name: tenant, currency: nil) }
  let!(:entry_definition) { tenant_definition.add_entry(code: entry_code, document: :user) }

  context "with non AR tenant" do
    let(:tenant_instance) { LedgerizerTest.new }

    it { expect { executor }.to raise_error("tenant must be an ActiveRecord model") }
  end

  context "with invalid AR tenant" do
    let(:tenant_instance) { create(:user) }

    it { expect { executor }.to raise_error("can't find tenant for given User model") }
  end

  context "when entry code is not in tenant" do
    let(:entry_code_param) { :register }

    it { expect { executor }.to raise_error("invalid entry code register for given tenant") }
  end

  describe "#add_movement" do
    let(:movement_type) { :debit }
    let(:account_name) { :cash }
    let(:account_type) { :asset }
    let(:contra) { false }
    let(:base_currency) { :clp }
    let(:accountable) { :user }
    let(:accountable_instance) { create(:user) }
    let(:amount) { clp(1000) }
    let(:executable_entry) { double }

    let(:account_definition) do
      Ledgerizer::Definition::Account.new(
        name: account_name,
        type: account_type,
        base_currency: base_currency,
        contra: contra
      )
    end

    let!(:movement_definition) do
      entry_definition.add_movement(
        movement_type: movement_type,
        account: account_definition,
        accountable: accountable
      )
    end

    def perform
      executor.add_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    it { expect(perform).to be_a(Ledgerizer::Execution::Movement) }
  end
end
