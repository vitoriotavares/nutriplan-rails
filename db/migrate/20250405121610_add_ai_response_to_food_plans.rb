class AddAiResponseToFoodPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :food_plans, :ai_response, :text
  end
end
