shared_examples "filtered lines by AR collection" do
  |collection_factory, line_filter_attr, filter_attr|
  def perform
    described_class.new(relation: nil, filters: filters).all.count
  end

  let(:item1) { create(collection_factory) }
  let(:item2) { create(collection_factory) }

  before do
    create_list(:ledgerizer_line, 5, line_filter_attr => item1)
    create_list(:ledgerizer_line, 2, line_filter_attr => item2)
    create_list(:ledgerizer_line, 3)
  end

  it { expect(perform).to eq(10) }

  context "with one item filter" do
    let(:filters) do
      {
        filter_attr => [item1]
      }
    end

    it { expect(perform).to eq(5) }
  end

  context "with multiple items filter" do
    let(:filters) do
      {
        filter_attr => [item1, item2]
      }
    end

    it { expect(perform).to eq(7) }
  end
end

shared_examples "filtered lines by syms collection" do |line_filter_attr, filter_attr|
  def perform
    described_class.new(relation: nil, filters: filters).all.count
  end

  let(:item1) { :code1 }
  let(:item2) { :code2 }

  before do
    create_list(:ledgerizer_line, 5, line_filter_attr => item1)
    create_list(:ledgerizer_line, 2, line_filter_attr => item2)
    create_list(:ledgerizer_line, 3)
  end

  it { expect(perform).to eq(10) }

  context "with one item filter" do
    let(:filters) do
      {
        filter_attr.to_s.pluralize.to_sym => [item1]
      }
    end

    it { expect(perform).to eq(5) }
  end

  context "with multiple items filter" do
    let(:filters) do
      {
        filter_attr.to_s.pluralize.to_sym => [item1, item2]
      }
    end

    it { expect(perform).to eq(7) }
  end
end

shared_examples "filtered lines by attribute" do |attr_value, line_filter_attr, filter_attr|
  def perform
    described_class.new(relation: nil, filters: filters).all.count
  end

  before do
    create_list(:ledgerizer_line, 5, line_filter_attr => attr_value)
    create_list(:ledgerizer_line, 3)
  end

  it { expect(perform).to eq(8) }

  context "with one item filter" do
    let(:filters) do
      {
        filter_attr => attr_value
      }
    end

    it { expect(perform).to eq(5) }
  end
end

shared_examples "filtered lines by polym_attr" do |factory, line_filter_attr, filter_attr|
  def perform
    described_class.new(relation: nil, filters: filters).all.count
  end

  let(:item1) { create(factory) }

  before do
    create_list(:ledgerizer_line, 5, line_filter_attr => create(factory))
    create_list(:ledgerizer_line, 3)
  end

  it { expect(perform).to eq(8) }

  context "with one item filter" do
    let(:filters) do
      {
        filter_attr => item1
      }
    end

    it { expect(perform).to eq(5) }
  end
end

shared_examples "filtered lines by predicated attribute" do
  |line_filter_attr, filter_attr, initial_value|
  let(:values) do
    result = []
    increment = initial_value.is_a?(Money) ? clp(10) : 10
    value = initial_value

    11.times do
      result << value
      value += increment
    end

    result
  end

  def perform
    described_class.new(relation: nil, filters: filters).all.count
  end

  before do
    values.each do |value|
      create(:ledgerizer_line, line_filter_attr => value)
    end
  end

  it { expect(perform).to eq(11) }

  context "without predicate" do
    let(:filters) do
      {
        filter_attr => values[2]
      }
    end

    it { expect(perform).to eq(1) }
  end

  context "with lt predicate" do
    let(:filters) do
      {
        "#{filter_attr}_lt" => values[3]
      }
    end

    it { expect(perform).to eq(3) }
  end

  context "with lteq predicate" do
    let(:filters) do
      {
        "#{filter_attr}_lteq" => values[3]
      }
    end

    it { expect(perform).to eq(4) }
  end

  context "with lt predicate" do
    let(:filters) do
      {
        "#{filter_attr}_gt" => values[3]
      }
    end

    it { expect(perform).to eq(7) }
  end

  context "with lteq predicate" do
    let(:filters) do
      {
        "#{filter_attr}_gteq" => values[3]
      }
    end

    it { expect(perform).to eq(8) }
  end
end
