module LedgerizerLinesRelated
  extend ActiveSupport::Concern

  included do
    def ledger_lines(filters = {})
      forbidden_line_filters.each { |f| filters.delete(f) }
      lines.filtered(filters)
    end

    def ledger_sum(filters = {})
      currency_filter = filters[:amount_currency] || currency
      ledger_lines(filters).amounts_sum(currency_filter)
    end

    def forbidden_line_filters
      raise "Not implemented forbidden_line_filters"
    end
  end
end
