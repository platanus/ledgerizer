shared_examples "ledgerizer tenant" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:accounts) }
  it { expect(entity).to have_many(:lines) }
  it { expect(entity).to have_many(:entries) }
end
