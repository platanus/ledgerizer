class CreateLedgerizerEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_entries do |t|
      t.references :tenant, polymorphic: true
      t.string :code
      t.references :document, polymorphic: true
      t.datetime :entry_time
    end

    add_index(
      :ledgerizer_entries,
      [
        :tenant_id,
        :tenant_type,
        :document_id,
        :document_type,
        :code
      ],
      unique: true,
      name: 'unique_entry_index'
    )
  end
end
