# Ledgerizer

### Definition

```ruby
Ledgerizer.setup do
  tenant(:portfolio) do
    accounts(currency: :clp) do
      asset :bank, currencies: [:usd, :eur]
      liability :funds_to_invest
      liability :to_invest_in_fund
      # etc.
    end

    effects do
      effect(:user_deposit, document: :user_deposit) do
        increase accountable: :bank, account: :bank
        increase accountable: :user, account: :funds_to_invest
      end

      effect(:user_deposit_distribution, document: :user_deposit) do
        decrease accountable: :user, account: :funds_to_invest
        increase accountable: :fund, account: :to_invest_in_fund
      end
    end
  end
end
```

De lo anterior:

- en `accounts` se define el currency base
- cada cuenta puede definir además otras currencies
- dentro de `accounts` se definen las cuentas que tiene el tenant.
- cada `effect` requiere un `document`. Si al momento de ejecutar el effext, no se pasa un document de ese tipo, da error.
- cada `effect` define que cuentas crecen y decrecen (`account`) y de quién son (`accountable`)

### Ejemplo de depósito de usario en Fintual

#### El usuario deposita dinero

```ruby
tenant = Portfolio.agf_portfolio
user = User.first
bank = Bank.first
amount = Money.new(1000)
user_deposit = UserDeposit.create!(amount: amount, user: user, bank: bank)

Ledgerizer::Effect.execute(
  :user_deposit,
  tenant: tenant,
  document: user_deposit,
  decrease: [{ account: :bank, accountable: bank, amount: amount }],
  increase: [{ account: :funds_to_invest, accountable: user, amount: amount }],
)

# Como es entre dos cuentas (que es lo más normal) podría aceptarse también:

Ledgerizer::Effect.execute(
  :user_deposit,
  tenant: tenant,
  document: user_deposit,
  amount: amount,
  decrease: { account: :bank, accountable: bank },
  increase: { account: :funds_to_invest, accountable: user },
)

# También estaría bueno usar un DSL. Yo hice algo para double entry parecido y creo que quedó bien.

include Ledgerizer::DSL

execute_user_deposit_effect(tenant: tenant, document: user_deposit, amount: amount) do
  decrease accountable: bank, account: :bank
  increase accountable: user, account: :funds_to_invest
end
```

El código anterior crearía:

1 - Si es que no existe, una `Account` con:

  - `code|name|category`: :bank # me gusta code
  - `accountable`: bank

2 - Si es que no existe, una `Account` con:

  - `code`: :funds_to_invest
  - `accountable`: user

3 - Una entrada en `Effect`s con:

  - code: :user_deposit
  - documentable: user_deposit

4 - Una `Line` con:

  - effect_id: del punto 3
  - account_id: del punto 1
  - amount: -amount

5 - Una `Line` con:

  - effect_id: del punto 3
  - account_id: del punto 2
  - amount: amount

#### El usuario selecciona el objetivo de su depósito. Esto hace que se distribuya en los diferentes fondos. Por ej: 70% Norris, 30% Pitt

```ruby
execute_user_deposit_distribution_effect(tenant: tenant, document: user_deposit, amount: amount) do
  decrease accountable: user, account: :funds_to_invest, amount: amount
  increase accountable: fund1, account: :to_invest_in_fund, amount: amount * 0.7
  increase accountable: fund2, account: :to_invest_in_fund, amount: amount * 0.3
end
```

El código anterior crearía:

1 - Si es que no existe, una `Account` con:

  - `code`: :funds_to_invest
  - `accountable`: user

2 - Si es que no existe, una `Account` con:

  - `code`: :to_invest_in_fund
  - `accountable`: fund1

3 - Si es que no existe, una `Account` con:

  - `code`: :to_invest_in_fund
  - `accountable`: fund2

4 - Una entrada en `Effect`s con:

  - code: :user_deposit_distribution
  - documentable: user_deposit

5 - Una `Line` con:

  - effect_id: del punto 4
  - account_id: del punto 1
  - amount: -amount

6 - Una `Line` con:

  - effect_id: del punto 4
  - account_id: del punto 2
  - amount: 700 clp

7 - Una `Line` con:

  - effect_id: del punto 4
  - account_id: del punto 3
  - amount: 300 clp

### Ventajas frente al modelo anterior.

- Cómo defino 2 effects que están asociados a un mismo document? de lo que entendí del documento de jaime, sería teniendo:
  un UserDeposit, un Effect para el depósito y uno para la distribución. A mí me hubiese gustado que un effect también fuera un modelo de ActiveRecord ya que siempre lleva uno asociado (document)

  Cuando el efecto es entre 2 cuentas el modelo se ve bien:

  ```ruby
  class UserDeposit < ApplicationRecord
    include Ledgerizer::Effect

    decrease :bank, :bank
    increase :user, :funds_to_invest
  end
  ```

  pero cuando involucra más cuentas?

  ```ruby
  class Order < ApplicationRecord
    decrease(:user, :funds_to_invest) # 1000
    increase(:fund, :to_invest_in_fund) # de dónde saca los 700?
    increase(:fund, :to_invest_in_fund) # de dónde saca los 300?

    monetize :amount_cents
  end
  ```

  > Lo anterior se puede solucionar generando dos Orders una por 300 y otra por 700 pero ahí ya no podríamos tener multiline.

  Para mí un modelo que permite pasar los montos como parámetros funciona mejor:

  ```ruby
  execute_user_deposit_distribution_effect(tenant: tenant, document: user_deposit, amount: amount) do
    decrease accountable: user, account: :funds_to_invest, amount: amount
    increase accountable: fund1, account: :to_invest_in_fund, amount: amount * 0.7
    increase accountable: fund2, account: :to_invest_in_fund, amount: amount * 0.3
  end
  ```

- No hace falta que defina las accounts en los modelos. Los effects determinan a qué cuentas está asociado cada modelo.
Es decir, cuando un usuario deposita por primera vez, se va a crear la cuenta con:

  - `code`: :funds_to_invest
  - `accountable`: user
