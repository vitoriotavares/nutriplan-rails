class CreateWaterPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :water_plans do |t|
      t.references :food_plan, null: false, foreign_key: true
      t.float :daily_amount
      t.text :recommendation

      t.timestamps
    end
  end
end
