class CreateMeals < ActiveRecord::Migration[8.0]
  def change
    create_table :meals do |t|
      t.references :food_plan, null: false, foreign_key: true
      t.string :name
      t.string :time
      t.string :objective
      t.integer :meal_type

      t.timestamps
    end
  end
end
