class CreateLedgerizerLines < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_lines do |t|
      t.references :tenant, polymorphic: true
      t.references :entry, foreign_key: { to_table: :ledgerizer_entries }
      t.date :entry_date
      t.string :entry_code
      t.string :account_type
      t.references :document, polymorphic: true
      t.references :account, foreign_key: { to_table: :ledgerizer_accounts }
      t.references :accountable, polymorphic: true
      t.string :account_name
      t.monetize :amount, amount: { null: false, default: 0 }

      t.timestamps
    end
  end
end
