module Ledgerizer
  class FilteredLinesQuery
    include Ledgerizer::Errors

    FILTERS_CONFIG = [
      { name: :tenant, filter_type: :attribute },
      { name: :entry, filter_type: :attribute },
      { name: :document, filter_type: :attribute },
      { name: :account, filter_type: :attribute },
      { name: :accountable, filter_type: :attribute },
      { name: :account_name, filter_type: :attribute },
      { name: :entry_code, filter_type: :attribute },
      { name: :account_type, filter_type: :attribute },

      { name: :tenants, filter_type: :collection },
      { name: :entries, filter_type: :collection },
      { name: :documents, filter_type: :collection },
      { name: :accounts, filter_type: :collection },
      { name: :accountables, filter_type: :collection },
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
      query = relation

      filters_config_by_attribute(:filter_type, :collection).each do |config|
        query = filter_by_collection(query, config)
      end

      filters_config_by_attribute(:filter_type, :attribute).each do |config|
        query = filter_by_attribute(query, config)
      end

      filters_config_by_attribute(:filter_type, :predicate).each do |config|
        query = filter_by_predicate(query, config)
      end

      query.order(entry_time: :desc, id: :desc)
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

    def filters_config_by_attribute(attribute, value)
      result = FILTERS_CONFIG.select { |config| config[attribute] == value }
      result.first if attribute == :name

      result
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
