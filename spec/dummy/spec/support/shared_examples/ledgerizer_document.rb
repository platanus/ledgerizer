shared_examples "ledgerizer document" do |entity_name|
  let(:entity) { create(entity_name) }

  let(:entry1) { create(:ledgerizer_entry, document: entity) }

  before do
    create_list(:ledgerizer_line, 3, entry: entry1)
    create_list(:ledgerizer_line, 2)
  end

  it { expect(Ledgerizer::Line.count).to eq(5) }
  it { expect(entity.lines.count).to eq(3) }
  it { expect(entity.entries.count).to eq(1) }
end
