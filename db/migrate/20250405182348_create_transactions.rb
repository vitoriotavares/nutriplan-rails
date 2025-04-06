class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subscription, null: false, foreign_key: true
      t.string :mercado_pago_transaction_id
      t.decimal :amount, precision: 8, scale: 2, null: false
      t.string :status, default: 'pending'
      t.string :payment_method
      t.text :description
      t.string :currency, default: 'BRL'
      t.jsonb :payment_details

      t.timestamps
    end
    
    add_index :transactions, :mercado_pago_transaction_id, unique: true
    add_index :transactions, :status
  end
end
