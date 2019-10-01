shared_examples "ledgerizer document" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:entries) }
  it { expect(entity).to have_many(:lines) }
end
