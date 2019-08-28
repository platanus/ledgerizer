shared_examples "currency" do |entity_name|
  let(:currency) { "CLP" }
  let(:entity) { build(entity_name, currency: currency) }

  it { expect(entity.save).to eq(true) }

  context "with invalid currency" do
    let(:currency) { "Invalid" }

    it { expect { entity.save! }.to raise_error(/Currency is invalid/) }
  end

  context "with nil currency" do
    let(:currency) { nil }

    it { expect { entity.save! }.to raise_error(/Currency is invalid/) }
  end

  context "with blank currency" do
    let(:currency) { "" }

    it { expect { entity.save! }.to raise_error(/Currency is invalid/) }
  end

  context "with symbol currency" do
    let(:currency) { :usd }

    it { expect(entity.save).to eq(true) }
  end

  context "with downcase currency" do
    let(:currency) { "usd" }

    it { expect(entity.save).to eq(true) }
  end
end
