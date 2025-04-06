module AnamnesisHelper
  def activity_level_translation(value)
    translations = {
      "sedentary" => "Sedentário",
      "lightly_active" => "Levemente ativo",
      "moderately_active" => "Moderadamente ativo",
      "very_active" => "Muito ativo",
      "extra_active" => "Extremamente ativo"
    }
    
    translations[value.to_s] || value.to_s.humanize
  end
  
  def exercise_frequency_translation(value)
    translations = {
      "none" => "Nenhuma",
      "1-2_per_week" => "1-2 vezes por semana",
      "3-4_per_week" => "3-4 vezes por semana",
      "5-6_per_week" => "5-6 vezes por semana",
      "daily" => "Diariamente"
    }
    
    translations[value.to_s] || value.to_s.humanize
  end
  
  def diet_type_translation(value)
    translations = {
      "omnivore" => "Onívora",
      "vegetarian" => "Vegetariana",
      "vegan" => "Vegana",
      "pescatarian" => "Pescetariana",
      "paleo" => "Paleolítica",
      "keto" => "Cetogênica",
      "gluten_free" => "Sem glúten",
      "lactose_free" => "Sem lactose",
      "low_carb" => "Baixo carboidrato",
      "mediterranean" => "Mediterrânea"
    }
    
    translations[value.to_s] || value.to_s.humanize
  end
  
  def weight_goal_translation(value)
    translations = {
      "lose_weight" => "Perda de peso",
      "gain_weight" => "Ganho de peso",
      "maintain_weight" => "Manutenção de peso",
      "gain_muscle" => "Ganho de massa muscular",
      "improve_health" => "Melhora da saúde geral"
    }
    
    translations[value.to_s] || value.to_s.humanize
  end
end
