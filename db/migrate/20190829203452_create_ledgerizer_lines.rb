class CreateLedgerizerLines < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_lines do |t|
      t.references :entry, foreign_key: { to_table: :ledgerizer_entries }
      t.datetime :entry_time
      t.string :entry_code

      t.references :account, foreign_key: { to_table: :ledgerizer_accounts }
      t.string :account_type
      t.string :account_name
      t.string :account_mirror_currency

      t.references :tenant, polymorphic: true
      t.references :document, polymorphic: true
      t.references :accountable, polymorphic: true

      t.monetize :amount, amount: { null: false, default: 0 }
      t.monetize :balance, amount: { null: false, default: 0 }
    end

    change_column :ledgerizer_lines, :amount_cents, :integer, limit: 8
    change_column :ledgerizer_lines, :balance_cents, :integer, limit: 8
  end
end
