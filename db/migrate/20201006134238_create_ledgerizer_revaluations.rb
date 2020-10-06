class CreateLedgerizerRevaluations < ActiveRecord::Migration[5.2]
  def change
    create_table :ledgerizer_revaluations do |t|
      t.datetime :revaluation_time
      t.monetize :amount, amount: { null: false, default: 0 }
    end

    change_column :ledgerizer_revaluations, :amount_cents, :integer, limit: 8

    add_index(
      :ledgerizer_revaluations,
      [
        :revaluation_time,
        :amount_currency,
      ],
      unique: true,
      name: 'unique_revaluations_index'
    )
  end
end
