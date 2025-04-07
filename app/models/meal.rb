class Meal < ApplicationRecord
  belongs_to :food_plan
  has_many :food_items, dependent: :destroy
  
  accepts_nested_attributes_for :food_items, allow_destroy: true, reject_if: :all_blank
  
  validates :name, :time, :objective, presence: true
  
  enum :meal_type, {
    breakfast: 0,
    morning_snack: 1,
    lunch: 2,
    afternoon_snack: 3,
    dinner: 4,
    evening_snack: 5
  }
  
  def total_calories
    food_items.sum { |item| item.calories || 0 }
  end
  
  def total_protein
    food_items.sum { |item| item.protein || 0 }
  end
  
  def total_carbs
    food_items.sum { |item| item.carbs || 0 }
  end
  
  def total_fat
    food_items.sum { |item| item.fat || 0 }
  end
end
