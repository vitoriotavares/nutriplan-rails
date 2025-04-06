class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true
      t.string :mercado_pago_subscription_id
      t.string :status, default: 'pending'
      t.datetime :current_period_start
      t.datetime :current_period_end
      t.datetime :canceled_at
      t.boolean :active, default: false
      t.boolean :auto_renew, default: true

      t.timestamps
    end
    
    add_index :subscriptions, :mercado_pago_subscription_id, unique: true
    add_index :subscriptions, [:user_id, :active]
  end
end
