module LedgerizerLinesRelated
  extend ActiveSupport::Concern

  included do
    def ledger_lines(filters = {})
      forbidden_line_filters.each { |f| filters.delete(f) }
      lines.filtered(filters)
    end

    def ledger_sum(filters = {})
      ledger_lines(filters).amounts_sum(currency)
    end

    def forbidden_line_filters
      raise "Not implemented forbidden_line_filters"
    end
  end
end
