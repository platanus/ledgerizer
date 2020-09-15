shared_examples "currency" do |entity_name, attribute = :currency|
  let(:currency) { "CLP" }
  let(:entity) { build(entity_name, attribute => currency) }

  def expect_to_include_error(attribute)
    entity.save
    expect(entity.errors.messages[attribute].first).to eq("is invalid")
  end

  def expect_not_to_include_error(attribute)
    entity.save
    expect(entity.errors.messages[attribute].first).not_to eq("is invalid")
  end

  it { expect_not_to_include_error(attribute) }

  context "with invalid currency" do
    let(:currency) { "Invalid" }

    it { expect_to_include_error(attribute) }
  end

  context "with nil currency" do
    let(:currency) { nil }

    it { expect_not_to_include_error(attribute) }
  end

  context "with blank currency" do
    let(:currency) { "" }

    it { expect_not_to_include_error(attribute) }
  end

  context "with symbol currency" do
    let(:currency) { :usd }

    it { expect_not_to_include_error(attribute) }
  end

  context "with downcase currency" do
    let(:currency) { "usd" }

    it { expect_not_to_include_error(attribute) }
  end
end
