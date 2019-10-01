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

### Consultas (lines) y balances

Antes de realizar consultas debemos agregar los concerns necesarios a cada modelo según lo que represente en la definición:

```ruby
class Portfolio < ApplicationRecord
  include LedgerizerTenant
end

class User < ApplicationRecord
  include LedgerizerAccountable
end

class Deposit < ApplicationRecord
  include LedgerizerDocument
end

```

Siguiendo el ejemplo, supongamos que luego de ejecutar algunas entries, tenemos:

```ruby
tenant = Portfolio.first
entry = Deposit.first.entries.first
account = User.first.accounts.first
```

Con esto podemos hacer:

*Para tenant*

- `tenant.accounts`: devuelve todas las `Ledgerizer::Account` asociadas al tenant
- `tenant.entries`: devuelve todas las `Ledgerizer::Entry` asociadas al tenant
- `tenant.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas al tenant
- `tenant.ledger_balance(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas al tenant

*Para entry*

- `entry.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas a la entry
- `entry.ledger_balance(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas a la entry

*Para account*

- `account.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas al account
- `account.ledger_balance(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas al account

Los métodos `ledger_lines` y `ledger_balance` aceptan los siguientes filtros:

- `entries`: Array de objetos `Ledgerizer::Entry`. También se puede usar `entry` para filtrar por un único objeto.
- `entry_codes`: Array de `code`s definidos en el `tenant`. En el ejemplo: `:user_deposit` y `user_deposit_distribution`. También se puede usar `entry_code` para filtrar por un único código.
- `accounts`: Array de objetos `Ledgerizer::Account`. También se puede usar `account` para filtrar por una única cuenta.
- `accountables`: Array de objetos `ActiveRecord` que son utilizados como `accountable` en `Ledgerizer::Account`s. En el ejemplo: `Bank.first` o `User.first`. También se puede usar `accountable` para filtrar por un único documento.
- `account_names`: Array de `name`s de cuentas definidos en el `tenant`. En el ejemplo: `:funds_to_invest` y `bank`. También se puede usar `account_name` para filtrar por un único nombre de cuenta.
- `account_types`: Array de tipos de cuenta. Puede ser: `asset`, `expense`, `liability`, `income` y `equity`. También se puede usar `account_type` para filtrar por un único tipo de cuenta.
- `documents`: Array de objetos `ActiveRecord` que son utilizados como `document` en `Ledgerizer::Entry`s. En el ejemplo: `UserDeposit.first`. También se puede usar `document` para filtrar por un único documento.
- `amount[_lt|_lteq|_gt|_gteq]`: Para filtrar por `amount` <, <=, > o >=. Debe ser una instancia de `Money` y si no se usa sufijo (_xxx) se buscará un monto igual.
- `entry_date[_lt|_lteq|_gt|_gteq]`: Para filtrar por `entry_date` <, <=, > o >=. Debe ser una instancia de `Date` y si no se usa sufijo (_xxx) se buscará una fecha igual.

> Se debe tener en cuenta que algunos filtros no harán sentido en aglunos contextos y por esto serán ignorados. Por ejemplo: si ejecuto `entry.ledger_balance(documents: [Deposit.last])`, el filtro `documents` será ignorado ya que ese filtro saldrá de `entry`.

#### Ejemplo de uso:

- Saber el balance de cada cuenta de tipo asset hasta el 10 de enero 2019. Para lograr esto, podría hacer:

  ```ruby
  tenant.accounts.where(account_type: :asset).each do |asset_account|
    p "#{asset_account.name}: #{asset_account.ledger_balance(entry_date_lteq: '2019-01-10')}"
  end
  ```

- Saber las líneas que conforman un una entry con código `user_deposit` para el día 10 de enero 2019.

  ```ruby
  tenant.ledger_lines(entry_code: :user_deposit, entry_date: '2019-01-10')
  ```

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
