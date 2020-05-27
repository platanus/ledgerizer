shared_examples "polymorphic attr" do |entity_name, attr_name, ar_entity_name, poro_entity_name|
  let(:entity) { build(entity_name) }
  let!(:ar_polymorphic_entity) { create(ar_entity_name) }
  let!(:poro_polymorphic_entity) { build(poro_entity_name) }

  it "sets/gets the AR polymorphic entity" do
    expect(entity.send(attr_name)).not_to eq(ar_polymorphic_entity)
    entity.send("#{attr_name}=", ar_polymorphic_entity)
    expect(entity.send(attr_name)).to eq(ar_polymorphic_entity)
  end

  it "sets the PORO polymorphic entity" do
    expect(entity.send(attr_name)).not_to eq(poro_polymorphic_entity)
    entity.send("#{attr_name}=", poro_polymorphic_entity)
    expect { entity.send(attr_name) }.to raise_error(
      /can't deserialize #{attr_name}, just ActiveRecord instances/
    )
  end
end
