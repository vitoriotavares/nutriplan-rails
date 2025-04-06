module FoodPlansHelper
  def meal_color(meal_type)
    colors = {
      'breakfast' => '#3498db',
      'morning_snack' => '#2ecc71',
      'lunch' => '#e74c3c',
      'afternoon_snack' => '#f39c12',
      'dinner' => '#9b59b6',
      'evening_snack' => '#1abc9c'
    }
    
    colors[meal_type.to_s] || '#3498db'
  end
end
