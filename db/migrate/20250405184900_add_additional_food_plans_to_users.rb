class AddAdditionalFoodPlansToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :additional_food_plans, :integer, default: 0, null: false
  end
end
