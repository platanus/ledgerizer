require "require_all"
require "money-rails"

require_rel "ledgerizer"

module Ledgerizer
  include Definition::Dsl

  def self.setup
    yield self
  end
end
