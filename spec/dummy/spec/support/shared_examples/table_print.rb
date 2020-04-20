shared_examples "table print" do
  describe "#to_table" do
    let(:result) { instance_double("TablePrint::Returnable") }

    context "with collection" do
      let(:table_print_source) do
        collection
      end

      it "calls table print with valid params" do
        expect(described_class).to receive(:tp).with(
          table_print_source, table_print_attrs
        ).and_return(result)

        expect(collection.to_table).to eq(result)
      end
    end

    context "with instance" do
      let(:table_print_source) do
        collection.where(id: collection.first.id)
      end

      it "calls table print with valid params" do
        expect(described_class).to receive(:tp).with(
          table_print_source, table_print_attrs
        ).and_return(result)

        expect(collection.first.to_table).to eq(result)
      end
    end
  end
end
