class Ledgerizer::Error < RuntimeError; end
class Ledgerizer::DslError < Ledgerizer::Error; end
class Ledgerizer::ConfigError < Ledgerizer::Error; end

module Ledgerizer
  module Errors
    def raise_error(msg)
      raise Ledgerizer::Error.new(msg)
    end

    def raise_config_error(msg)
      raise Ledgerizer::ConfigError.new(msg)
    end

    def raise_dsl_definition_error(msg)
      raise Ledgerizer::DslError.new(msg)
    end
  end
end
