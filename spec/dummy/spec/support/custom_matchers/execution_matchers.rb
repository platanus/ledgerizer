RSpec::Matchers.define :have_ledger_entry do |entry_code:, entry_time:, document:|
  match do |tenant|
    !!Ledgerizer::Entry.find_by(
      tenant_id: tenant.id,
      tenant_type: tenant.class.to_s,
      code: entry_code,
      document_id: document.id,
      document_type: document.class.to_s,
      entry_time: entry_time
    )
  end

  description do
    "include #{entry_code} entry with with date #{entry_time} and #{document.class} document"
  end

  failure_message do
    "#{entry_code} with given params is not a tenant's entry"
  end
end

RSpec::Matchers.define :have_ledger_line do |
  accountable:, amount:, balance: nil, account_name: nil, account: nil
|
  acc = account_name || account
  fail "missing account_name" unless acc

  match do |entry|
    currency = amount.currency.to_s
    account = Ledgerizer::Account.find_by(
      tenant_id: entry.tenant.id,
      tenant_type: entry.tenant.class.to_s,
      name: acc,
      accountable_id: accountable&.id,
      accountable_type: accountable.blank? ? nil : accountable.class.to_s,
      currency: currency
    )

    line_params = {
      amount_cents: amount.cents,
      amount_currency: currency,
      account: account
    }

    if balance
      line_params[:balance_cents] = balance.cents
      line_params[:balance_currency] = balance.currency.to_s
    end

    !!entry.lines.find_by(line_params)
  end

  description do
    "include line with #{acc} account and #{amount} amount"
  end

  failure_message do
    "line with given params is not in entry"
  end
end
