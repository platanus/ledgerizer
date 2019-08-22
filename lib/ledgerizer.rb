require "require_all"

require_rel "ledgerizer"

module Ledgerizer
  def self.setup
    yield self
  end
end
