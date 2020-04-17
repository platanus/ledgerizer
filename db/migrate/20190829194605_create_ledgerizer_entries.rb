class CreateLedgerizerEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_entries do |t|
      t.references :tenant, polymorphic: true
      t.string :code
      t.references :document, polymorphic: true
      t.datetime :entry_time
    end
  end
end
