class LedgerizerTest
  # empty, to be overwritten
end

module TestClassHelpers
  extend ActiveSupport::Concern

  included do
    def test_class_include_ledgerizer?
      LedgerizerTest.included_modules.include?(Ledgerizer::Definition::Dsl)
    end

    def mock_ledgerizer_definition
      allow(Ledgerizer).to receive(:definition).and_return(LedgerizerTest.definition)
    end

    before do
      if respond_to?(:test_class)
        stub_const("LedgerizerTest", test_class)
        mock_ledgerizer_definition if test_class_include_ledgerizer?
      end
    end
  end

  class_methods do
    def define_test_class(&block)
      let(:test_class) do
        Class.new(&block)
      end
    end
  end
end
