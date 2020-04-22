module Ledgerizer
  class FilteredLinesQuery
    include Ledgerizer::Errors

    FILTERS_CONFIG = [
      { name: :entry, filter_type: :attribute },
      { name: :account, filter_type: :attribute },
      { name: :account_name, filter_type: :attribute },
      { name: :entry_code, filter_type: :attribute },
      { name: :account_type, filter_type: :attribute },

      { name: :tenant, filter_type: :polym_attr },
      { name: :document, filter_type: :polym_attr },
      { name: :accountable, filter_type: :polym_attr },

      { name: :entries, filter_type: :collection },
      { name: :accounts, filter_type: :collection },
      { name: :account_names, filter_type: :collection },
      { name: :entry_codes, filter_type: :collection },
      { name: :account_types, filter_type: :collection },

      { name: :entry_time, filter_type: :predicate },
      { name: :entry_time_lt, filter_type: :predicate },
      { name: :entry_time_lteq, filter_type: :predicate },
      { name: :entry_time_gt, filter_type: :predicate },
      { name: :entry_time_gteq, filter_type: :predicate },

      { name: :amount, filter_type: :predicate, data_type: :money },
      { name: :amount_lt, filter_type: :predicate, data_type: :money },
      { name: :amount_lteq, filter_type: :predicate, data_type: :money },
      { name: :amount_gt, filter_type: :predicate, data_type: :money },
      { name: :amount_gteq, filter_type: :predicate, data_type: :money  }
    ]

    PREDICATES = {
      lt: '<',
      lteq: '<=',
      gt: '>',
      gteq: '>='
    }

    def initialize(relation: nil, filters: {})
      @relation = relation || Ledgerizer::Line.all
      @filters = format_filters(filters)
    end

    def all
      q = relation
      filters_config_by_type(:collection).each { |conf| q = filter_by_collection(q, conf) }
      filters_config_by_type(:polym_attr).each { |conf| q = filter_by_polym_attr(q, conf) }
      filters_config_by_type(:attribute).each { |conf| q = filter_by_attribute(q, conf) }
      filters_config_by_type(:predicate).each { |conf| q = filter_by_predicate(q, conf) }
      q.sorted
    end

    private

    attr_reader :relation, :filters

    def format_filters(hash)
      return {} if hash.blank?

      hash.keys.each do |filter_name|
        if !valid_filters.include?(filter_name.to_sym)
          raise_query_error("invalid filter #{filter_name}")
        end
      end

      hash.with_indifferent_access
    end

    def filters_config_by_type(value)
      FILTERS_CONFIG.select { |config| config[:filter_type] == value }
    end

    def valid_filters
      @valid_filters ||= FILTERS_CONFIG.map { |config| config[:name] }
    end

    def filter_by_collection(query, config)
      filter_values = filters[config[:name]]
      return query if filter_values.blank?

      query.where(config[:name].to_s.singularize => filter_values)
    end

    def filter_by_attribute(query, config)
      filter_value = filters[config[:name]]
      return query if filter_value.blank?

      query.where(config[:name] => filter_value)
    end

    def filter_by_polym_attr(query, config)
      filter_value = filters[config[:name]]
      return query if filter_value.blank?

      query.where("#{config[:name]}_id" => filter_value.id)
      query.where("#{config[:name]}_type" => filter_value.class.to_s)
    end

    def filter_by_predicate(query, config)
      filter_value = filters[config[:name]]
      return query if filter_value.blank?

      filter_name_parts = config[:name].to_s.split("_")
      condition = PREDICATES[filter_name_parts.pop.to_sym] || '='
      attribute = condition == '=' ? config[:name] : filter_name_parts.join("_")

      case config[:data_type]
      when :money
        query.where(
          "#{attribute}_cents #{condition} ? AND #{attribute}_currency = ?",
          filter_value.cents,
          filter_value.currency.to_s
        )
      else
        query.where("#{attribute} #{condition} ?", filter_value)
      end
    end
  end
end
