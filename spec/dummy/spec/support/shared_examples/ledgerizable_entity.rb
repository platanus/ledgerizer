shared_examples "ledgerizable entity" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity.to_type_attr).to eq(entity.class.to_s) }
  it { expect(entity.to_id_attr).to eq(entity.id) }

  context "with nil id" do
    before { allow(entity).to receive(:id).and_return(nil) }

    it { expect(entity.to_type_attr).to be_nil }
    it { expect(entity.to_id_attr).to be_nil }
  end

  context "with entity not implementing id method" do
    let_test_class do
      include LedgerizableEntity
    end

    let(:entity) { test_class.new }

    it { expect { entity.to_id_attr }.to raise_error(/must implement id method/) }
  end
end
