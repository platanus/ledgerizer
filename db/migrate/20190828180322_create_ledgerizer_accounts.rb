class CreateLedgerizerAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_accounts do |t|
      t.references :tenant, polymorphic: true
      t.references :accountable, polymorphic: true, index: { name: "index_ledgerizer_accounts_on_acc_type_and_acc_id" }
      t.string :name
      t.string :currency
      t.string :account_type
      t.monetize :balance, amount: { null: false, default: 0 }

      t.timestamps
    end

    add_index(
      :ledgerizer_accounts,
      [
        :accountable_type,
        :accountable_id,
        :name,
        :account_type,
        :currency,
        :tenant_id,
        :tenant_type
      ],
      unique: true,
      name: 'unique_account_index'
    )
  end
end
