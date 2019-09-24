require "enumerize"
require "require_all"
require "money-rails"

require_rel "ledgerizer/extensions/*.rb"
require_rel "ledgerizer/util/*.rb"
require_rel "ledgerizer/shared/*.rb"
require_rel "ledgerizer/definition/*.rb"
require_rel "ledgerizer/execution/*.rb"
require_rel "ledgerizer/engine.rb"

module Ledgerizer
  include Definition::Dsl

  def self.setup
    yield self
  end
end
