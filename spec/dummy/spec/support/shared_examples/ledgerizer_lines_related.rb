shared_examples "ledgerizer lines related" do |entity_name|
  let(:entity) { create(entity_name) }

  describe "#ledger_lines/sum" do
    let(:filters) do
      Ledgerizer::FilteredLinesQuery.new.send(:valid_filters).inject({}) do |result, filter_name|
        result[filter_name] = double
        result
      end
    end

    let(:expected_filters) do
      expected = {}

      filters.each do |k, v|
        expected[k] = v unless entity.forbidden_line_filters.include?(k)
      end

      expected
    end

    let(:lines) { double }
    let(:filtered_lines) { double }
    let(:currency) { double }

    def ledger_lines
      entity.ledger_lines(filters)
    end

    def ledger_sum
      entity.ledger_sum(filters)
    end

    before do
      allow(entity).to receive(:lines).and_return(lines)
      allow(lines).to receive(:filtered).and_return(filtered_lines)
      allow(filtered_lines).to receive(:amounts_sum).and_return(true)
      allow(entity).to receive(:currency).and_return(currency)
    end

    it "calls Line#filtered method with valid params" do
      ledger_lines

      expect(lines).to have_received(:filtered)
        .with(expected_filters)
    end

    it "calls Line#amounts_sum method with valid params" do
      ledger_sum

      expect(lines).to have_received(:filtered)
        .with(expected_filters)

      expect(filtered_lines).to have_received(:amounts_sum)
    end
  end
end
