RSpec::Matchers.define :have_ledger_entry do |entry_code:, entry_date:, document:|
  match do |tenant|
    !!Ledgerizer::Entry.find_by(
      tenant: tenant,
      code: entry_code,
      document: document,
      entry_date: entry_date
    )
  end

  description do
    "include #{entry_code} entry with with date #{entry_date} and #{document.class} document"
  end

  failure_message do
    "#{entry_code} with given params is not a tenant's entry"
  end
end

RSpec::Matchers.define :have_ledger_line do
  |account_name:, accountable:, amount:, movement_type: nil|
  match do |entry|
    currency = amount.currency.to_s
    account = Ledgerizer::Account.find_by(
      tenant: entry.tenant,
      name: account_name,
      accountable: accountable,
      currency: currency
    )

    !!entry.lines.find_by(
      amount_cents: amount.cents,
      amount_currency: currency,
      account: account
    )
  end

  description do
    "include line with #{account_name} account and #{amount} amount"
  end

  failure_message do
    "line with given params is not in entry"
  end
end