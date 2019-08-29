Money.locale_backend = :currency

MoneyRails.configure do |config|
  # To set the default currency
  #
  config.default_currency = :clp

  # Set default bank object
  #
  # Example:
  # config.default_bank = EuCentralBank.new

  # Add exchange rates to current money bank object.
  # (The conversion rate refers to one direction only)
  #
  # Example:
  # config.add_rate "USD", "CAD", 1.24515
  # config.add_rate "CAD", "USD", 0.803115

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  # config.include_validations = true

  # Default ActiveRecord migration configuration values for columns:
  #
  config.amount_column[:type] = :bigint
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_cents',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix
  #                                                # and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: 'USD'
  #                          }

  # Register a custom currency
  #
  # Example:
  # config.register_currency = {
  #   :priority            => 1,
  #   :iso_code            => "EU4",
  #   :name                => "Euro with subunit of 4 digits",
  #   :symbol              => "€",
  #   :symbol_first        => true,
  #   :subunit             => "Subcent",
  #   :subunit_to_unit     => 10000,
  #   :thousands_separator => ".",
  #   :decimal_mark        => ","
  # }

  config.register_currency = {
    priority: 100,
    iso_code: "CLP",
    name: "Chilean Peso",
    symbol: "$",
    disambiguate_symbol: "CLP$",
    alternate_symbols: [],
    subunit: "Peso",
    subunit_to_unit: 10000,
    symbol_first: true,
    html_entity: "&#36;",
    decimal_mark: ",",
    thousands_separator: ".",
    smallest_denomination: 10000
  }

  config.register_currency = {
    priority: 101,
    iso_code: "MXN",
    name: "Mexican Peso",
    symbol: "$",
    disambiguate_symbol: "MXN$",
    alternate_symbols: [],
    subunit: "Peso",
    subunit_to_unit: 1000000,
    symbol_first: true,
    html_entity: "&#36;",
    decimal_mark: ".",
    thousands_separator: ",",
    smallest_denomination: 1000000
  }

  # Set money formatted output globally.
  # Default value is nil meaning "ignore this option".
  # Options are nil, true, false.
  #
  config.no_cents_if_whole = true
  config.rounding_mode = BigDecimal::ROUND_HALF_UP
  # config.symbol = nil
end
