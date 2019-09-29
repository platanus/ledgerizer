# Ledgerizer

A double-entry accounting system for Rails applications

## Installation

Add to your Gemfile:

```ruby
gem "ledgerizer"
```

```bash
bundle install
```

```bash
rails g ledgerizer:install
```

## Usage

### Definición

Luego de correr el instalador, se debe definir (usando el DSL de definición): tenants, accounts y entries.
El formato es el siguiente:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:tenant_name1) do
    conf.asset :account_name1
    conf.asset :account_name2
    conf.liability :account_name3
    conf.liability :account_name4
    conf.liability :account_name5
    conf.equity :account_name6
    conf.income :account_name7
    conf.expense :account_name8
    conf.equity :account_name9
    # more accounts...

    conf.entry :entry_code1, document: :document1 do
      conf.debit account: :account_name1, accountable: :accountable1
      conf.credit account: :account_name4, accountable: :accountable2
    end

    conf.entry :entry_code2, document: :document2 do
      conf.debit account: :account_name4, accountable: :accountable2
      conf.credit account: :account_name5, accountable: :accountable1
      conf.credit account: :account_name6, accountable: :accountable3
    end

    # more entries...
  end

  conf.tenant(:tenant_name2) do
    # more definitions...
  end
end
```

#### Métodos del DSL

1. `tenant`: un negocio puede llevar la contabilidad de distintas entidades. Los `tenant` representan esas entidades.
el nombre de un tenant, debe ser el nombre de un modelo de `ActiveRecord`.

2. `asset`: define una cuenta de este tipo. De forma similar se definen cuentas para representar: `liability`, `equity`, `income` y `expense`.

3. `entry`: representa un movimiento contable entre 2 o más cuentas. Cada entrada está asociada a un `document` del negocio. Este `document` debe ser un modelo `ActiveRecord`

4. `debit/credit`: se usan dentro de una `entry` y definen hacia qué dirección se mueve el capital. Además asocian una cuenta a un modelo de `ActiveRecord` (a través de `accountable`)

#### Ejemplo:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:portfolio) do
    conf.asset :bank
    conf.liability :funds_to_invest
    conf.liability :to_invest_in_fund

    conf.entry :user_deposit, document: :user_deposit do
      conf.debit account: :bank, accountable: :bank
      conf.credit account: :funds_to_invest, accountable: :user
    end

    conf.entry :user_deposit_distribution, document: :user_deposit do
      conf.debit account: :funds_to_invest, accountable: :user
      conf.credit account: :to_invest_in_fund, accountable: :user
    end
  end
end
```

### Ejecución

Una vez definidas las entries, podremos crear movimientos en la DB.
Para hacer esto, debemos incluir el DSL de ejecución así:

```ruby
# Suponemos que existen los modelos de ActiveRecord Portfolio, UserDeposit, User y Bank.

class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.first, document: UserDeposit.first, date: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'CLP'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(10, 'CLP'))
    end
  end
end
```

La ejecución de `DepositCreator.new.perform` creará:

1. Dos `Ledgerizer::Account`

  - Una con `name: 'bank'`, `tenant: Portfolio.first`, `accountable: Bank.first`, `account_type: 'asset'` y `currency: 'CLP'`

  - Otra con `name: 'funds_to_invest'`, `tenant: Portfolio.first`, `accountable: User.first`, `account_type: 'liability' y `currency: 'CLP'`


2. Una `Ledgerizer::Entry` con: `code: 'user_deposit'`, `tenant: Portfolio.first`, `document: UserDeposit.first` y `entry_date: '1984-06-04'`


3. Dos `Ledgerizer::Line`. Una por cada movimiento de la entry.

  - Una con `entry_id: apuntando a la entry del punto 2`, `account_id: apuntando a 1.1`, `amount: 10 CLP`

  - Una con `entry_id: apuntando a la entry del punto 2`, `account_id: apuntando a 1.2`, `amount: 10 CLP`

### Tener en cuenta

- Cada `Ledgerizer::Line` además incluye información desnormalizada para facilitar consultas. Esto es: `tenant`, `document`, `entry_date`, `entry_code`
- Al ejecutar una entry, se puede dividir el monto en n movmientos siempre y cuando se respete lo que está en la definición para esa entry. Por ej, algo como lo siguiente, sería válido:

  ```ruby
  class DepositCreator
    include Ledgerizer::Execution::Dsl

    def perform
      execute_user_deposit_entry(tenant: Portfolio.first, document: UserDeposit.first, date: "1984-06-04") do
        debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'CLP'))
        credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(6, 'CLP'))
        credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(3, 'CLP'))
        credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(1, 'CLP'))
      end
    end
  end
  ```

- Los montos de los movimientos deben estar de acuerdo con https://en.wikipedia.org/wiki/Trial_balance


## Testing

To run the specs you need to execute, **in the root path of the gem**, the following command:

```bash
bundle exec guard
```

You need to put **all your tests** in the `/ledgerizer/spec/dummy/spec/` directory.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

Thank you [contributors](https://github.com/platanus/ledgerizer/graphs/contributors)!

<img src="http://platan.us/gravatar_with_text.png" alt="Platanus" width="250"/>

Ledgerizer is maintained by [platanus](http://platan.us).

## License

Ledgerizer is © 2019 platanus, spa. It is free software and may be redistributed under the terms specified in the LICENSE file.
