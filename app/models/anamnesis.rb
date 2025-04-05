class Anamnesis < ApplicationRecord
  belongs_to :user
  has_many :food_plans, dependent: :destroy
  
  # Definindo acessores para campos JSON
  store_accessor :health_data, :height, :weight, :date_of_birth, :gender, :blood_type, :allergies
  store_accessor :dietary_preferences, :favorite_foods, :disliked_foods, :meal_frequency, :diet_type
  store_accessor :restrictions, :food_allergies, :intolerances, :medical_restrictions
  store_accessor :lifestyle, :activity_level, :exercise_frequency, :occupation, :stress_level, :sleep_hours
  store_accessor :goals, :weight_goal, :health_objectives, :target_date, :specific_needs
  
  validates :user_id, presence: true
  
  def bmi
    return nil unless health_data && health_data['height'].present? && health_data['weight'].present?
    
    height_m = health_data['height'].to_f / 100
    weight_kg = health_data['weight'].to_f
    
    return nil if height_m <= 0
    
    (weight_kg / (height_m ** 2)).round(2)
  end
  
  def age
    return nil unless health_data && health_data['date_of_birth'].present?
    
    dob = Date.parse(health_data['date_of_birth']) rescue nil
    return nil unless dob
    
    now = Time.current.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end
  
  def calculate_bmr
    return nil unless health_data && 
                      health_data['weight'].present? && 
                      health_data['height'].present? && 
                      health_data['gender'].present? && 
                      age
    
    weight = health_data['weight'].to_f
    height = health_data['height'].to_f
    gender = health_data['gender'].to_s.downcase
    
    # Fórmula de Harris-Benedict
    if gender == 'male'
      88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age)
    else
      447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age)
    end
  end
  
  def calculate_daily_calories
    return nil unless calculate_bmr && lifestyle && lifestyle['activity_level'].present?
    
    bmr = calculate_bmr
    activity_level = lifestyle['activity_level'].to_s.downcase
    
    # Multiplicadores baseados no nível de atividade
    multiplier = case activity_level
                 when 'sedentary'
                   1.2
                 when 'lightly_active'
                   1.375
                 when 'moderately_active'
                   1.55
                 when 'very_active'
                   1.725
                 when 'extra_active'
                   1.9
                 else
                   1.2
                 end
    
    (bmr * multiplier).round
  end
  
  def calculate_macros(calories = nil)
    calories ||= calculate_daily_calories
    return nil unless calories
    
    # Distribuição padrão de macronutrientes (pode ser ajustada com base em goals)
    protein_percentage = 0.25
    fat_percentage = 0.25
    carb_percentage = 0.5
    
    # Ajuste com base em diet_type se disponível
    if dietary_preferences && dietary_preferences['diet_type'].present?
      diet = dietary_preferences['diet_type'].to_s.downcase
      
      case diet
      when 'low_carb'
        protein_percentage = 0.30
        fat_percentage = 0.45
        carb_percentage = 0.25
      when 'high_protein'
        protein_percentage = 0.40
        fat_percentage = 0.30
        carb_percentage = 0.30
      when 'keto'
        protein_percentage = 0.20
        fat_percentage = 0.70
        carb_percentage = 0.10
      end
    end
    
    # Cálculo de gramas (proteína e carboidrato = 4 calorias/g, gordura = 9 calorias/g)
    protein_grams = ((calories * protein_percentage) / 4).round
    fat_grams = ((calories * fat_percentage) / 9).round
    carb_grams = ((calories * carb_percentage) / 4).round
    
    {
      calories: calories,
      protein: protein_grams,
      fat: fat_grams,
      carbs: carb_grams,
      protein_percentage: (protein_percentage * 100).round,
      fat_percentage: (fat_percentage * 100).round,
      carb_percentage: (carb_percentage * 100).round
    }
  end
end
