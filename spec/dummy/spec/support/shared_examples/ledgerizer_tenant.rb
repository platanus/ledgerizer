shared_examples "ledgerizer active record tenant" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:accounts) }
  it { expect(entity).to have_many(:lines) }
  it { expect(entity).to have_many(:entries) }
end

shared_examples "ledgerizer PORO tenant" do |entity_name|
  let(:entity) { create(entity_name) }

  before do
    create_list(:ledgerizer_line, 3, force_tenant: entity)
    create_list(:ledgerizer_line, 2)
  end

  it { expect(entity.lines.count).to eq(3) }
end

shared_examples "ledgerizer tenant" do |entity_name|
  let(:entity) { create(entity_name) }

  describe "#create_entry!" do
    let(:code) { :deposit }
    let(:document) { create(:user) }
    let(:entry_time) { "1984-06-06" }

    let(:executable_entry) do
      instance_double(
        "Ledgerizer::Execution::Entry",
        code: code,
        document: document,
        entry_time: entry_time
      )
    end

    def perform
      entity.create_entry!(executable_entry)
    end

    context "with valid entry" do
      let(:expected_attributes) do
        {
          code: "deposit",
          document: document,
          entry_time: entry_time.to_datetime,
          tenant_id: entity.id,
          tenant_type: entity.class.to_s
        }
      end

      it { expect { perform }.to change { entity.entries.count }.from(0).to(1) }
      it { expect(perform).to have_attributes(expected_attributes) }
    end

    context "with invalid attributes" do
      let(:code) { nil }

      it { expect { perform }.to raise_error(ActiveRecord::RecordInvalid) }
    end
  end

  describe "#account_type_balance, #account_balance" do
    let(:account_type) { :asset }
    let(:account_name) { :account1 }
    let(:currency) { "CLP" }
    let(:currency_param) { currency }

    def account_type_balance
      entity.account_type_balance(account_type, currency_param)
    end

    def account_balance
      entity.account_balance(account_name, currency_param)
    end

    before do
      create(
        :ledgerizer_account,
        tenant: entity,
        name: :account1,
        currency: currency,
        account_type: :asset,
        balance: clp(10)
      )

      create(
        :ledgerizer_account,
        tenant: entity,
        name: :account2,
        currency: currency,
        account_type: :liability,
        balance: clp(8)
      )

      create(
        :ledgerizer_account,
        tenant: entity,
        name: :account1,
        currency: currency,
        account_type: :asset,
        balance: clp(10)
      )

      create(
        :ledgerizer_account,
        tenant: entity,
        name: :account3,
        currency: currency,
        account_type: :asset,
        balance: clp(12)
      )
    end

    it { expect(account_type_balance).to eq(clp(32)) }
    it { expect(account_balance).to eq(clp(20)) }

    context "with different type" do
      let(:account_type) { :liability }

      it { expect(account_type_balance).to eq(clp(8)) }
    end

    context "with missing type" do
      let(:account_type) { :missing }

      it { expect(account_type_balance).to eq(clp(0)) }
    end

    context "with different account name" do
      let(:account_name) { :account3 }

      it { expect(account_balance).to eq(clp(12)) }
    end

    context "with missing account name" do
      let(:account_name) { :account4 }

      it { expect(account_balance).to eq(clp(0)) }
    end

    context "with symbol currency" do
      let(:currency_param) { :clp }

      it { expect(account_type_balance).to eq(clp(32)) }
      it { expect(account_balance).to eq(clp(20)) }
    end
  end
end
