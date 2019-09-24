class LedgerizerTest
  # empty, to be overwritten
end

class LedgerizerTestDefinitionBase
  include Ledgerizer::Definition::Dsl
end

class LedgerizerTestDefinition
  # empty, to be overwritten
end

module TestClassHelpers
  extend ActiveSupport::Concern

  included do
    before do
      stub_const("LedgerizerTest", test_class) if respond_to?(:test_class)

      if respond_to?(:definition_class)
        stub_const("LedgerizerTestDefinition", definition_class)
        allow(Ledgerizer).to receive(:definition).and_return(LedgerizerTestDefinition.definition)
      end
    end
  end

  class_methods do
    def let_test_class(&block)
      let(:test_class) do
        Class.new(&block)
      end
    end

    def let_definition_class(&block)
      let(:definition_class) do
        Class.new(LedgerizerTestDefinitionBase, &block)
      end
    end
  end
end
