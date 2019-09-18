module ErrorHelpers
  extend ActiveSupport::Concern

  included do
    def expect_error_in_class_definition(error, &block)
      expect { Class.new(&block) }.to raise_error(Ledgerizer::Error, error)
    end
  end
end
