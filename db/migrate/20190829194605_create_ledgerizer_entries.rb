class CreateLedgerizerEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_entries do |t|
      t.references :tenant, polymorphic: true
      t.string :code
      t.references :document, polymorphic: true
      t.datetime :entry_time
      t.string :mirror_currency
      t.monetize :conversion_amount, amount: { null: true }
    end

    change_column :ledgerizer_entries, :conversion_amount_cents, :integer, limit: 8

    add_index(
      :ledgerizer_entries,
      [
        :tenant_id,
        :tenant_type,
        :document_id,
        :document_type,
        :code,
        :mirror_currency
      ],
      length: {
        document_type: 50,
        mirror_currency: 10,
        tenant_type: 50
      },
      unique: true,
      name: 'unique_entry_index'
    )
  end
end
