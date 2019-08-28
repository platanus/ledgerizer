class CreateLedgerizerAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_accounts do |t|
      t.references :tenant, polymorphic: true
      t.string :name
      t.string :currency
      t.string :account_type

      t.timestamps
    end
  end
end
