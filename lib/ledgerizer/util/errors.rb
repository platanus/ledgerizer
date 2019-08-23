class Ledgerizer::Error < RuntimeError; end
class Ledgerizer::DslError < Ledgerizer::Error; end
class Ledgerizer::ConfigError < Ledgerizer::Error; end
