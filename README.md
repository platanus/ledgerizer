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

  - Otra con `name: 'funds_to_invest'`, `tenant: Portfolio.new`, `accountable: User.first`, `account_type: 'liability'` y `currency: 'CLP'`


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

### Multi-Currency

Las cuentas de ledgerizer se pueden definir para trabajar con más de un tipo de moneda. Si tengo la siguiente definición:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:portfolio, currency: :clp) do
    conf.asset :bank, currencies: [:usd]
    conf.liability :funds_to_invest, currencies: [:usd]

    conf.entry :user_deposit, document: :deposit do
      conf.debit account: :bank, accountable: :bank
      conf.credit account: :funds_to_invest, accountable: :user
    end
  end
end
```
se podrá ejecutar la entry `user_deposit` para dos tipos de moneda: la base definida en el tenant (CLP) y la definida en `currencies: []` (en este caso USD). Por ejemplo:

```ruby
class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'USD'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(10, 'USD'))
    end
  end
end
```
y

```ruby
class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04") do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(1000, 'CLP'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(1000, 'CLP'))
    end
  end
end
```

serían dos entradas válidas.

Tener en cuenta:

- Por cada currency, existirá una cuenta. Es decir que si ejecutamos las dos anteriores, tendremos 4 cuentas: 2 en CLP y 2 en USD.
- Siempre las cuentas se crean en la moneda base definida en el tenant. Es decir que si omites la opción `currencies`, se asumirá que esa cuenta tiene la misma moneda que el tenant.
- Si no se define la opción `currency` en el tenant, se usará la que viene por defecto en la gema Money (`Money.default_currency`). Es decir, siempre existirá una moneda base.

#### Cuentas espejo

Opcionalmente en entries que trabajan con cuentas multicurrency se puede especificar un `conversion_amount`. Al hacer esto, si corremos el siguiente código:

```ruby
class DepositCreator
  include Ledgerizer::Execution::Dsl

  def perform
    execute_user_deposit_entry(tenant: Portfolio.new, document: UserDeposit.first, datetime: "1984-06-04", conversion_amount: Money.from_amount(600, 'CLP')) do
      debit(account: :bank, accountable: Bank.first, amount: Money.from_amount(10, 'USD'))
      credit(account: :funds_to_invest, accountable: User.first, amount: Money.from_amount(10, 'USD'))
    end
  end
end
```

obtendremos 2 entries. La primera contendrá líneas por los 10 USD (monto original) y la segunda por su equivalente en la moneda del tenant (CLP). En este caso, dos líneas de 6000 CLP que es el resultado de multiplicar 10 USD x 600 CLP (valor de conversión).
> Cabe destacar que además se generarán cuentas especiales para llevar el balance de estos montos convertidos.

#### Revalorizaciones

Como vimos anteriormente, Ledgerizer nos permite registrar entries en una currency distinta a la del tenant. Además, permite llevar esos montos en la moneda del tenant haciendo uso de las cuentas espejo. Ejemplo:

La siguiente configuración representa el cobro de una comisión por el intercambio de criptomonedas en un exchange:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:portfolio, currency: :clp) do
    conf.asset :funds, currencies: [:btc]
    conf.income :trade_transaction_fee, currencies: [:btc]

    conf.entry :user_trade_fee, document: :bank_movement do
      conf.debit account: :funds, accountable: :wallet
      conf.credit account: :trade_transaction_fee
    end
  end
end
```

Si ejecuto la entry que registra el cobro de la comisión así:

```ruby
execute_user_trade_fee_entry(tenant: Portfolio.new, document: BankMovement.first, datetime: "2020-01-01", conversion_amount: Money.from_amount(9000000, 'CLP')) do
  debit(account: :funds, accountable: Wallet.first, amount: Money.from_amount(2, 'BTC'))
  credit(account: :trade_transaction_fee, amount: Money.from_amount(2, 'BTC'))
end
```

En el día 2020-01-01:

- Se registarán los 2 BTC en las cuentas que corresponda.
- Se registrará su equivalente en CLP (2 BTC * 9000000 CLP = 18000000 CLP) en las cuentas espejo.

Supongamos que pasa el tiempo (es 2020-10-01) y el BTC aumenta su valor a 12000000 CLP.
Si miramos la cuenta espejo, nos dirá que tenemos 18000000 CLP algo que al día de hoy no es cierto ya que en realidad tenemos 2 BTC * 12000000 CLP = 24000000 CLP.
Para lograr que la cuenta espejo refleje esta realidad es que necesitamos del mecanismo de revalorización. Se configura así:

```ruby
Ledgerizer.setup do |conf|
  conf.tenant(:portfolio, currency: :clp) do
    conf.asset :funds, currencies: [:btc]
    conf.income :trade_transaction_fee, currencies: [:btc]

    config.revaluation :crypto_exposure do
      conf.account :funds, accountable: :wallet
    end

    conf.entry :user_trade_fee, document: :bank_movement do
      conf.debit account: :funds, accountable: :wallet
      conf.credit account: :trade_transaction_fee
    end
  end
end
```

A `config.revaluation` se le pasa el nombre que identifica la revalorización. En este caso: `:crypto_exposure` y dentro, todas aquellas cuentas que necesitan ser revalorizadas. En este caso, el `asset` llamado `funds`.

La ejecución es así:

```ruby
execute_crypto_exposure_revaluation(
  tenant: Portfolio.first,
  currency: :btc,
  datetime: "2020-01-01".to_datetime,
  conversion_amount: Money.new(12000000, :clp),
  account_name: :funds,
  accountable: Wallet.first
)
```

Por debajo este código calculará la diferencia (en la moneda del tenant) entre lo que tenía en la cuenta espejo y lo que debería tener en la actualidad así:

```
valor_registrado = 18000000 CLP
valor_actual = 2 BTC * conversion_amount (12000000 CLP) = 24000000 CLP
diferencia = valor_actual - valor_registrado (6000000 CLP)
```

Esta diferencia luego se registrará como un `income` en una cuenta `positive_crypto_exposure_asset_revaluation` y también en la cuenta espejo `funds` (`asset`)

Tener en cuenta:

- Si la diferencia resultara ser negativa, se contabilizará en el `expense` llamado `negative_crypto_exposure_asset_revaluation` y también en la cuenta espejo `funds` (`asset`) pero esta vez como un crédito para reducir su valor.
- Las revalorizaciones también pueden hacerse contra cuentas de tipo `liability`.
- Es posible revalorizar múltiples cuentas contra una `revaluation` así:

  ```ruby
  Ledgerizer.setup do |conf|
    conf.tenant(:tenant1, currency: :clp) do
      conf.asset :account1, currencies: [:btc]
      conf.asset :account2, currencies: [:btc]

      config.revaluation :rev1 do
        conf.account :account1, accountable: :accountable1
        conf.account :account2, accountable: :accountable2
      end
    end
  end
  ```
- Solo pueden revalorizarse cuentas con moneda distinta al tenant. Es decir, que tengan cuenta espejo.


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
