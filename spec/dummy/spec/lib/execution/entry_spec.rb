require "spec_helper"

describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    build(
      :executable_entry,
      config: ledgerizer_config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_time: entry_time
    )
  end

  let(:ledgerizer_config) { LedgerizerTestDefinition.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:document) { :deposit }
  let(:document_instance) { create(:deposit) }
  let(:entry_code) { :deposit }
  let(:entry_time) { "1984-06-04" }
  let(:entry_instance_date) { entry_time }

  let(:entry) do
    create(
      :ledgerizer_entry,
      tenant: tenant_instance,
      document: document_instance,
      code: entry_code,
      entry_time: entry_instance_date
    )
  end

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1)
      liability(:account2)

      entry(:deposit, document: :deposit) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
      end
    end
  end

  it { expect(execution_entry.entry_time).to eq(entry_time.to_datetime) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with invalid tenant type" do
    let(:tenant_instance) { "tenant" }

    it { expect { execution_entry }.to raise_error(/of a class including LedgerizerTenant/) }
  end

  context "with invalid tenant" do
    let(:tenant_instance) { create(:user) }

    it { expect { execution_entry }.to raise_error(/tenant must be an instance of a class/) }
  end

  context "with non class document" do
    let(:document_instance) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error(/document must be an instance of a class/) }
  end

  context "with invalid document" do
    let(:document_instance) { create(:portfolio) }

    it { expect { execution_entry }.to raise_error(/of a class including LedgerizerDocument/) }
  end

  context "with not valid entry code for given tenant" do
    let(:entry_code) { "buy" }

    it { expect { execution_entry }.to raise_error("invalid entry code buy for given tenant") }
  end

  context "with invalid date" do
    let(:entry_time) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid datetime given") }
  end

  describe "#entry_instance" do
    def instance
      execution_entry.entry_instance
    end

    it { expect { instance }.to change(Ledgerizer::Entry, :count).from(0).to(1) }
    it { expect(instance).to be_a(Ledgerizer::Entry) }
    it { expect(instance.tenant).to eq(tenant_instance) }
    it { expect(instance.code).to eq(entry_code.to_s) }
    it { expect(instance.document).to eq(document_instance) }
    it { expect(instance.entry_time).to eq(entry_time.to_datetime) }

    context "with persisted entry" do
      before { entry }

      it { expect { instance }.not_to change(Ledgerizer::Entry, :count) }
      it { expect(instance).to eq(entry) }
    end
  end

  describe "#add_new_movement" do
    let(:movement_type) { :debit }
    let(:amount) { clp(1000) }
    let(:account_name) { :account1 }
    let(:accountable_instance) { create(:user) }

    def perform
      execution_entry.add_new_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    it { expect { perform }.to change { execution_entry.new_movements.count }.from(0).to(1) }

    context "with non class accountable" do
      let(:accountable_instance) { LedgerizerTest.new }

      it { expect { perform }.to raise_error(/nstance of a class including LedgerizerAccountable/) }
    end

    context "with invalid accountable" do
      let(:accountable_instance) { create(:client) }

      it { expect { perform }.to raise_error(/accountable Client for given deposit entry in debi/) }
    end

    context "with no definition for matching given movement type" do
      let(:movement_type) { :credit }

      let(:error_msg) do
        'invalid movement account1 with accountable User for given deposit entry in credits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition for matching given account name" do
      let(:account_name) { :account2 }

      let(:error_msg) do
        'invalid movement account2 with accountable User for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition matching given accountable" do
      let(:accountable_instance) { create(:client) }

      let(:error_msg) do
        'invalid movement account1 with accountable Client for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with invalid amount" do
      let(:amount) { 666 }

      let(:error_msg) do
        'invalid money'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end
  end

  describe "#related_accounts" do
    let(:account_name1) { :account1 }
    let(:account_name2) { :account2 }

    let(:account_type1) { :asset }
    let(:account_type2) { :liability }

    let(:accountable1) { create(:user) }
    let(:accountable2) { create(:user) }
    let(:accountable3) { create(:user) }

    let(:expected_accounts) do
      [
        build(
          :executable_account,
          tenant: tenant_instance,
          accountable: accountable1,
          account_name: account_name1,
          account_type: account_type1,
          currency: "CLP"
        ),
        build(
          :executable_account,
          tenant: tenant_instance,
          accountable: accountable2,
          account_name: account_name2,
          account_type: account_type2,
          currency: "CLP"
        ),
        build(
          :executable_account,
          tenant: tenant_instance,
          accountable: accountable3,
          account_name: account_name2,
          account_type: account_type2,
          currency: "CLP"
        )
      ]
    end

    def perform
      execution_entry.related_accounts.sort
    end

    before do
      execution_entry.add_new_movement(
        movement_type: :debit,
        account_name: account_name1,
        accountable: accountable1,
        amount: clp(10)
      )

      execution_entry.add_new_movement(
        movement_type: :credit,
        account_name: account_name2,
        accountable: accountable2,
        amount: clp(5)
      )

      execution_entry.add_new_movement(
        movement_type: :credit,
        account_name: account_name2,
        accountable: accountable3,
        amount: clp(5)
      )
    end

    it { expect(perform).to eq(expected_accounts) }

    context "with persisted entry adding a new account" do
      let(:accountable4) { create(:user) }
      let(:updated_expected_accounts) do
        expected_accounts + [
          build(
            :executable_account,
            tenant: tenant_instance,
            accountable: accountable4,
            account_name: account_name2,
            account_type: account_type2,
            currency: "CLP"
          )
        ]
      end

      before do
        create(
          :ledgerizer_line,
          entry: entry,
          account: create(
            :ledgerizer_account,
            tenant: tenant_instance,
            name: account_name2,
            accountable: accountable4,
            account_type: account_type2
          )
        )
      end

      it { expect(perform).to eq(updated_expected_accounts) }
    end

    context "with previous entry not adding a new account" do
      before do
        create(
          :ledgerizer_line,
          entry: entry,
          account: create(
            :ledgerizer_account,
            tenant: tenant_instance,
            name: account_name1,
            accountable: accountable1,
            account_type: account_type1
          )
        )
      end

      it { expect(perform).to eq(expected_accounts) }
    end
  end
end
