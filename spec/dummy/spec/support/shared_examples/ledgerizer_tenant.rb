shared_examples "ledgerizer tenant" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:accounts) }
  it { expect(entity).to have_many(:lines) }
  it { expect(entity).to have_many(:entries) }

  describe "#create_entry!" do
    let(:code) { :deposit }
    let(:document) { create(:user) }
    let(:entry_date) { "1984-06-06" }

    let(:executable_entry) do
      instance_double(
        "Ledgerizer::Execution::Entry",
        code: code,
        document: document,
        entry_date: entry_date
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
          entry_date: entry_date.to_date,
          tenant: entity
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

  describe "#find_or_create_account_from_executable_movement!" do
    let(:accountable) { create(:deposit) }
    let(:account_name) { :account1 }
    let(:currency) { :clp }
    let(:account_type) { :asset }

    let(:movement) do
      instance_double(
        "Ledgerizer::Execution::Movement",
        accountable: accountable,
        account_name: account_name,
        base_currency: currency,
        account_type: account_type
      )
    end

    def perform
      entity.find_or_create_account_from_executable_movement!(movement)
    end

    context "with valid movement" do
      let(:expected_attributes) do
        {
          name: "account1",
          accountable: accountable,
          currency: "CLP",
          tenant: entity,
          account_type: "asset"
        }
      end

      it { expect { perform }.to change { entity.accounts.count }.from(0).to(1) }
      it { expect(perform).to have_attributes(expected_attributes) }

      context "with existent account" do
        before { create(:ledgerizer_account, expected_attributes) }

        it { expect { perform }.not_to(change { entity.accounts.count }) }
      end
    end

    context "with invalid attributes" do
      let(:account_name) { nil }

      it { expect { perform }.to raise_error(ActiveRecord::RecordInvalid) }
    end
  end
end
