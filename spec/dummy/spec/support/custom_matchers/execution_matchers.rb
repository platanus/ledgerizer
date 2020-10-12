# rubocop:disable Layout/LineLength
RSpec::Matchers.define :have_ledger_entry do |entry_code:, entry_time:, document:, conversion_amount: nil, mirror_currency: nil|
  match do |tenant|
    entry_params = {
      tenant_id: tenant.id,
      tenant_type: tenant.class.to_s,
      code: entry_code,
      document_id: document.id,
      document_type: document.class.to_s,
      entry_time: entry_time,
      mirror_currency: mirror_currency,
      conversion_amount_cents: nil
    }

    if conversion_amount
      entry_params[:conversion_amount_cents] = conversion_amount.cents
      entry_params[:conversion_amount_currency] = conversion_amount.currency.to_s
    end

    !!Ledgerizer::Entry.find_by(entry_params)
  end

  description do
    "include #{entry_code} entry with with date #{entry_time} and #{document.class} document"
  end

  failure_message do
    "#{entry_code} with given params is not a tenant's entry"
  end
end

RSpec::Matchers.define :have_ledger_line do |accountable:, amount:, balance: nil, account_name: nil, account: nil, mirror_currency: nil|
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
      mirror_currency: mirror_currency,
      currency: currency
    )

    line_params = {
      account: account,
      amount_cents: amount.cents,
      amount_currency: currency
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
# rubocop:enable Layout/LineLength
