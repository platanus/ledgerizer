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
end
