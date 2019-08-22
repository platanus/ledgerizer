class LedgerizerTest
  # empty, to be overwritten
end

module TestClassHelpers
  extend ActiveSupport::Concern

  included do
    before { stub_const("LedgerizerTest", test_class) if respond_to?(:test_class) }
  end

  class_methods do
    def define_test_class(&block)
      let(:test_class) do
        Class.new(&block)
      end
    end
  end
end
