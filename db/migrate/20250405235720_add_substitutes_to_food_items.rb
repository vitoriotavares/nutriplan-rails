class AddSubstitutesToFoodItems < ActiveRecord::Migration[8.0]
  def change
    add_column :food_items, :substitutes, :text
  end
end
