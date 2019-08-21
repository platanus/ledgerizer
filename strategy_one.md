### Ejemplo de depósito de usario en Fintual

Dentro del initializer

```ruby
Ledgerizer.setup do
  asset(:bank)
  liability(:funds_to_invest)
  liability(:to_invest_in_fund)
  # ... y todas las demás
end
```

```ruby
class User < ApplicationRecord
  accounts :funds_to_invest
end
```

```ruby
class Bank < ApplicationRecord
  accounts :bank
end
```

```ruby
class UserDeposit < ApplicationRecord
  include Ledgerizer::Effect

  decrease :bank, :bank
  increase :user, :funds_to_invest

  monetize :amount_cents

  def date
    created_at.to_date
  end

  # == Schema Information
  #
  # Table name: user_deposits
  #
  #  id                :bigint(8)        not null, primary key
  #  amount_cents      :bigint(8)
  #  amount_currency   :string
  #  user_id           :bigint(8)
  #  bank_id           :bigint(8)
  #  created_at        :datetime         not null
  #  updated_at        :datetime         not null
end
```

Luego para ejecutar...

```ruby
UserDeposit.create!(amount: Money.new(1000), user: User.first, bank: Bank.first)
# quizás hacer esto en el callback? o ejecutarlo a manopla luegro
```

Lo anterior me generaría:

1) una entrada en la tabla effects que tendría:

```
documentable = user_deposit
date = user_deposit.date
```

2) dos lines una aumentando 1000 apuntando a un accound_id y la otra restando 1000 apuntando a otro account_id

Un objeto `Account` tendría:

- `code` (lo que entienden como category) (ej: bank, funds_to_invest, etc)
- `accountable` (User, Bank, etc)
- Lo del Money que dice Griffero.

Las líneas que se crearían:

1 - `account(:bank, Bank.first), amount: -Money.new(1000), documentable: la instancia de UserDeposit`

2 - `account(:funds_to_invest, User.first), amount: Money.new(1000), documentable: la instancia de UserDeposit`

### Ejemplo de distribución en los distintos fondos:

```ruby
class Fund < ApplicationRecord
  accounts :to_invest_in_fund
end
```

```ruby
class Order < ApplicationRecord
  decrease(:user, :funds_to_invest)
  increase(:fund, :to_invest_in_fund)

  monetize :amount_cents

  def date
    created_at.to_date
  end

  #  user_deposit_id  :bigint(8)
  #  fund_id         :bigint(8)
  #  amount_cents    :bigint(8)        default(0), not null
  #  amount_currency :string           default("CLP"), not null
  #  created_at       :datetime         not null
  #  updated_at       :datetime         not null
end
```

En algún momento el usuario decide a que objetivo va su plata y entonces se produce la distribución.
Supongamos que tengo 2 fondos se divide 70% para el primero y 30% para el segundo...


```ruby
Order.create!(amount: Money.new(1000) * 0.7, user: User.first, fund: fund1)
Order.create!(amount: Money.new(1000) * 0.3, user: User.first, fund: fund2)
```

Las líneas que se crearían:

1 - `account(:funds_to_invest, User.first), amount: -Money.new(700), documentable: instancia de Order 1`

2 - `account(:to_invest_in_fund, fund1), amount: Money.new(700), documentable: instancia de Order 1`

3 - `account(:funds_to_invest, User.first), amount: -Money.new(300), documentable: instancia de Order 2`

4- `account(:to_invest_in_fund, fund2), amount: Money.new(300), documentable: instancia de Order 2`

### Cosas que omití deliberadamente para tener una versión simple:

- tenant
- multiple currency
- effect type (creo que podría ahcerse con otro effect)
- action (creo que el nombre del effect dice cuál es la intención)

### Tener en cuenta/Ideas futuro:

Para tener tenant, se podría defindir en el initializer así:

```ruby
Ledgerizer.setup do
  tenant(:portfolio) do
    asset(:bank)
    liability(:funds_to_invest)
    liability(:to_invest_in_fund)
    # ... y todas las demás
  end
end
```

En el ejemplo de la distribución, sería bueno que todos los movimientos quedaran relacionados. Podríamos para eso tener un:

```ruby
class Ledgerizer::Operation < ApplicationRecord
end
```
