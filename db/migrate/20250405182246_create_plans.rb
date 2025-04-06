class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 8, scale: 2, null: false
      t.integer :food_plans_limit, default: 1
      t.boolean :full_recipe_access, default: false
      t.boolean :priority_support, default: false
      t.string :mercado_pago_id
      t.boolean :active, default: true
      t.boolean :is_default, default: false

      t.timestamps
    end
    
    add_index :plans, :name, unique: true
  end
end
