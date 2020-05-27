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
El nombre de un tenant, debe ser el nombre de un modelo de `ActiveRecord` (o clase de Ruby) que incluye el módulo `LedgerizerTenant`.

2. `asset`: define una cuenta de este tipo. De forma similar se definen cuentas para representar: `liability`, `equity`, `income` y `expense`.

3. `entry`: representa un movimiento contable entre 2 o más cuentas. Cada entrada está asociada a un `document` del negocio. Este `document` debe ser un modelo `ActiveRecord` (o clase de Ruby) que incluye el módulo `LedgerizerDocument`.

4. `debit/credit`: se usan dentro de una `entry` y definen hacia qué dirección se mueve el capital. Además, asocian un modelo de `ActiveRecord` (o clase de Ruby) que incluye el módulo `LedgerizerAccountable` a una cuenta a través de el atributo `accountable`.
 > `accountable` puede ser `nil` si se desea que la cuenta no quede asociada a una entidad específica.

#### Ejemplo:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:portfolio) do
    conf.asset :bank
    conf.liability :funds_to_invest
    conf.liability :to_invest_in_fund

    conf.entry :user_deposit, document: :deposit do
      conf.debit account: :bank, accountable: :bank
      conf.credit account: :funds_to_invest, accountable: :user
    end

    conf.entry :user_deposit_distribution, document: :deposit do
      conf.debit account: :funds_to_invest, accountable: :user
      conf.credit account: :to_invest_in_fund, accountable: :user
    end
  end
end
```

#### Ledgerizar modelos y clases

Parte de la definición consiste en incluir los módulos de `Ledgerizer` en los modelos/clases que corresponda.

- Todos los modelos/clases definidos como `tenant`, deben incluir: `LedgerizerTenant`
- Todos los modelos/clases definidos como `document`, deben incluir: `LedgerizerDocument`
- Todos los modelos/clases definidos como `accountable`, deben incluir: `LedgerizerAccountable`

> Se debe tener en cuenta que un modelo/clase no puede ser usado con dos roles distintos. Por ejemplo: si `User` es un `accountable`, no podrá ser usado como `document`.

```ruby
class Portfolio
  include LedgerizerTenant

  def id
    999 # Es obligatorio usar un id.
  end
end

class Bank
  include LedgerizerAccountable

  def id
    666 # Es obligatorio usar un id.
  end
end

class User < ApplicationRecord
  include LedgerizerAccountable
end

class Deposit < ApplicationRecord
  include LedgerizerDocument
end
```

> Como pueden ver en el ejemplo, usé clases de `ActiveRecord` para `User` y `Deposit` pero para `Bank` y `Portfolio` clases normales de Ruby. El uso de una cosa u otra dependerá de la necesidad de la aplicación.

### Ejecución

Una vez definidas las entries, podremos crear movimientos en la DB.
Para hacer esto, debemos incluir el DSL de ejecución así:

```ruby
# Suponemos que existen los modelos de ActiveRecord UserDeposit, User y Bank y una clase Ruby (Portfolio) que usaremos de tenant .

class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'CLP'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(10, 'CLP'))
    end
  end
end
```

La ejecución de `DepositCreator.new.perform` creará:

1. Dos `Ledgerizer::Account`

  - Una con `name: 'bank'`, `tenant: Portfolio.new`, `accountable: Bank.first`, `account_type: 'asset'` y `currency: 'CLP'`

  - Otra con `name: 'funds_to_invest'`, `tenant: Portfolio.new`, `accountable: User.first`, `account_type: 'liability' y `currency: 'CLP'`


2. Una `Ledgerizer::Entry` con: `code: 'user_deposit'`, `tenant: Portfolio.new`, `document: UserDeposit.first` y `entry_time: '1984-06-04'`


3. Dos `Ledgerizer::Line`. Una por cada movimiento de la entry.

  - Una con `entry_id: apuntando a la entry del punto 2`, `account_id: apuntando a 1.1`, `amount: 10 CLP`

  - Una con `entry_id: apuntando a la entry del punto 2`, `account_id: apuntando a 1.2`, `amount: 10 CLP`

### Tener en cuenta

- Cada `Ledgerizer::Line` además incluye información desnormalizada para facilitar consultas. Esto es: `tenant`, `document`, `entry_time`, `entry_code`
- Al ejecutar una entry, se puede dividir el monto en n movmientos siempre y cuando se respete lo que está en la definición para esa entry. Por ej, algo como lo siguiente, sería válido:

  ```ruby
  class DepositCreator
    include Ledgerizer::Execution::Dsl

    def perform
      execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
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

Siguiendo el ejemplo, supongamos que luego de ejecutar algunas entries, tenemos:

```ruby
tenant = Portfolio.new
entry = Deposit.first.entries.first
account = User.first.accounts.first
```

Con esto podemos hacer:

*Para tenant*

- `tenant.account_balance(account_name, currency)`: devuelve el balance de una cuenta. Ejemplo: `tenant.account_balance(:bank, "CLP")`
- `tenant.account_type_balance(account_type, currency)`: devuelve el balance de un tipo de cuenta. Ejemplo: `tenant.account_type_balance(:asset, "CLP")`. Los tipos pueden ser: `asset, expense, liability, income, equity`
- `tenant.accounts`: devuelve todas las `Ledgerizer::Account` asociadas al tenant
- `tenant.entries`: devuelve todas las `Ledgerizer::Entry` asociadas al tenant
- `tenant.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas al tenant
- `tenant.ledger_sum(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas al tenant

*Para entry*

- `entry.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas a la entry
- `entry.ledger_sum(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas a la entry

*Para account*

- `account.balance`: devuelve el balance de la cuenta desde caché
- `account.balance_at(date)`: devuelve el balance de la cuenta desde caché hasta una fecha
- `account.ledger_lines(filters)`: devuelve todas las `Ledgerizer::Line` asociadas al account
- `account.ledger_sum(filters)`: devuelve la suma de todas las `Ledgerizer::Line` asociadas al account

Los métodos `ledger_lines` y `ledger_sum` aceptan los siguientes filtros:

- `entries`: Array de objetos `Ledgerizer::Entry`. También se puede usar `entry` para filtrar por un único objeto.
- `entry_codes`: Array de `code`s definidos en el `tenant`. En el ejemplo: `:user_deposit` y `user_deposit_distribution`. También se puede usar `entry_code` para filtrar por un único código.
- `accounts`: Array de objetos `Ledgerizer::Account`. También se puede usar `account` para filtrar por una única cuenta.
- `account_names`: Array de `name`s de cuentas definidos en el `tenant`. En el ejemplo: `:funds_to_invest` y `bank`. También se puede usar `account_name` para filtrar por un único nombre de cuenta.
- `account_types`: Array de tipos de cuenta. Puede ser: `asset`, `expense`, `liability`, `income` y `equity`. También se puede usar `account_type` para filtrar por un único tipo de cuenta.
- `amount[_lt|_lteq|_gt|_gteq]`: Para filtrar por `amount` <, <=, > o >=. Debe ser una instancia de `Money` y si no se usa sufijo (_xxx) se buscará un monto igual.
- `entry_time[_lt|_lteq|_gt|_gteq]`: Para filtrar por `entry_time` <, <=, > o >=. Debe ser una instancia de `DateTime` y si no se usa sufijo (_xxx) se buscará una fecha/hora igual.

> Se debe tener en cuenta que algunos filtros no harán sentido en algunos contextos y por esto serán ignorados. Por ejemplo: si ejecuto `entry.ledger_sum(document: Deposit.last)`, el filtro `document` será ignorado ya que ese filtro saldrá de `entry`.

#### Ejemplo de uso:

- Saber el balance de cada cuenta de tipo asset hasta el 10 de enero 2019. Para lograr esto, podría hacer:

  ```ruby
  tenant.accounts.where(account_type: :asset).each do |asset_account|
    p "#{asset_account.name}: #{asset_account.ledger_sum(entry_time_lteq: '2019-01-10')}"
  end
  ```

- Saber las líneas que conforman un una entry con código `user_deposit` para el día 10 de enero 2019.

  ```ruby
  tenant.ledger_lines(entry_code: :user_deposit, entry_time: '2019-01-10')
  ```

#### Table print

Puede resultar útil mostrar en la consola información de `accounts`, `entries` o `lines`. Ejemplos:

```ruby
Ledgerizer::Account.to_table # para mostrar todas las cuentas
```

```
ID | ACCOUNT_TYPE | CURRENCY | NAME     | ACCOUNTABLE_ID | ACCOUNTABLE_TYPE | TENANT_ID | TENANT_TYPE | BALANCE.FORMAT
---|--------------|----------|----------|----------------|------------------|-----------|-------------|---------------
1  | asset        | CLP      | account1 | 1              | User             | 999       | Portfolio   | $161
5  | liability    | CLP      | account2 | 4              | User             | 999       | Portfolio   | $225
2  | liability    | CLP      | account2 | 6              | User             | 999       | Portfolio   | $204
4  | asset        | CLP      | account1 | 2              | User             | 999       | Portfolio   | $230
7  | liability    | CLP      | account2 | 5              | User             | 999       | Portfolio   | $193
9  | asset        | CLP      | account1 | 3              | User             | 999       | Portfolio   | $231
```

```ruby
User.first.accounts.to_table # Para mostrar las cuentas de un accountable
```

```
ID | ACCOUNT_TYPE | CURRENCY | NAME     | ACCOUNTABLE_ID | ACCOUNTABLE_TYPE | TENANT_ID | TENANT_TYPE | BALANCE.FORMAT
---|--------------|----------|----------|----------------|------------------|-----------|-------------|---------------
1  | asset        | CLP      | account1 | 1              | User             | 999       | Portfolio   | $161
```

```ruby
Ledgerizer::Account.first.lines.to_table # para mostrar las lines de una cuenta
```

```
ID  | ACCOUNT_NAME | ACCOUNTABLE_ID | ACCOUNTABLE_TYPE | ACCOUNT_ID | DOCUMENT_ID | DOCUMENT_TYPE | ACCOUNT_TYPE | ENTRY_CODE | ENTRY_TIME              | ENTRY_ID | TENANT_ID | TENANT_TYPE | AMOUNT.FORMAT | BALANCE.FORMAT
----|--------------|----------------|------------------|------------|-------------|---------------|--------------|------------|-------------------------|----------|-----------|-------------|---------------|---------------
381 | account1     | 1              | User             | 1          | 252         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 192      | 999       | Portfolio   | $2            | $161
378 | account1     | 1              | User             | 1          | 251         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 191      | 999       | Portfolio   | $2            | $159
369 | account1     | 1              | User             | 1          | 246         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 186      | 999       | Portfolio   | $1            | $157
357 | account1     | 1              | User             | 1          | 241         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 181      | 999       | Portfolio   | $2            | $156
349 | account1     | 1              | User             | 1          | 237         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 177      | 999       | Portfolio   | $4            | $154
297 | account1     | 1              | User             | 1          | 211         | Deposit       | asset        | test       | 2020-04-17 22:23:11     | 151      | 999       | Portfolio   | $5            | $150
...
```

```ruby
Ledgerizer::Entry.first.to_table # para mostrar una instancia como tabla.
```

```
ID | ENTRY_TIME              | DOCUMENT_ID | DOCUMENT_TYPE | CODE | TENANT_ID | TENANT_TYPE
---|-------------------------|-------------|---------------|------|-----------|------------
1  | 2020-04-17 22:23:11     | 64          | Deposit       | test | 1         | Portfolio
```

### Ajuste de Entries

Este mecanismo sirve para corregir errores en entries creadas con anterioridad.
Toda entry que se ejecute con el mismo `document` y `datetime` más de una vez, será considerada un ajuste y debido a esto se reemplazarán las lines de la entry previamente guardada.

Siguendo con el ejemplo del `DepositCreator`...

```ruby
class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'CLP'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(10, 'CLP'))
    end
  end
end
```

Si lo ejecuto una vez, obtendré las dos líneas que mencioné anteriormente:

- Una relacionada con la cuenta `bank` por `amount: 10 CLP`

- Una relacionada con la cuenta `funds_to_invest` por `amount: 10 CLP`

Hasta aquí es un caso normal. Ahora supongamos que tenenmos la siguiente clase que modifica solo los montos de `DepositCreator`.

```ruby
class DepositFixer
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(15, 'CLP'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(15, 'CLP'))
    end
  end
end
```

Al ejecutar el `DepositFixer` se borrarán las líneas:

- La relacionada con la cuenta `bank` por `amount: 10 CLP`

- La relacionada con la `funds_to_invest` por `amount: 10 CLP`

y se agregarán 2 nuevas:

- Una relacionada con la cuenta `bank` por `amount: 15 CLP`

- Una relacionada con la cuenta `funds_to_invest` por `amount: 15 CLP`

## Testing

To run the specs you need to execute, **in the root path of the gem**, the following command:

```bash
bundle exec guard
```

You need to put **all your tests** in the `/ledgerizer/spec/dummy/spec/` directory.

### Jackhammer

Inspirado en [double entry](https://github.com/envato/double_entry#jackhammer)...

Se puede correr el siguiente comando:

```bash
bin/jack_hammer -p 5 -e 50
```

Para probar que al ejecutar varias entries, de manera concurrente, todas las líneas y balances se generan correctamente.

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
