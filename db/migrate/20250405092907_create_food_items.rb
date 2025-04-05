class CreateFoodItems < ActiveRecord::Migration[8.0]
  def change
    create_table :food_items do |t|
      t.references :meal, null: false, foreign_key: true
      t.string :name
      t.float :quantity
      t.string :unit

      t.timestamps
    end
  end
end
