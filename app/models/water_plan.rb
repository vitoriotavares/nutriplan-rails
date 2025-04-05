class WaterPlan < ApplicationRecord
  belongs_to :food_plan
  
  validates :daily_amount, numericality: { greater_than: 0 }, allow_nil: true
  
  def glasses_per_day
    return 0 unless daily_amount
    
    (daily_amount / 250).ceil # Considerando um copo de 250ml
  end
  
  def calculate_recommended_amount(weight, activity_level = :moderate)
    # Cálculo básico baseado no peso (em kg) e nível de atividade
    base_amount = weight * 35 # 35ml por kg de peso corporal
    
    # Ajuste baseado no nível de atividade
    activity_multiplier = case activity_level.to_sym
                          when :sedentary
                            0.8
                          when :moderate
                            1.0
                          when :active
                            1.2
                          when :very_active
                            1.5
                          else
                            1.0
                          end
    
    (base_amount * activity_multiplier).round
  end
  
  def distribution_schedule
    return [] unless daily_amount && daily_amount > 0
    
    glass_size = 250 # ml
    glasses = glasses_per_day
    
    # Distribuição ao longo do dia
    schedule = []
    
    # Ao acordar
    schedule << { time: "Ao acordar", amount: glass_size, description: "1 copo ao acordar" }
    
    # Durante a manhã
    schedule << { time: "Manhã", amount: glass_size * 2, description: "2 copos entre o café da manhã e o almoço" }
    
    # Durante a tarde
    schedule << { time: "Tarde", amount: glass_size * 2, description: "2 copos entre o almoço e o jantar" }
    
    # Durante a noite
    schedule << { time: "Noite", amount: glass_size, description: "1 copo após o jantar" }
    
    # Adiciona copos extras se necessário
    if glasses > 6
      extra_glasses = glasses - 6
      schedule << { time: "Distribuído", amount: glass_size * extra_glasses, description: "#{extra_glasses} copos extras distribuídos ao longo do dia" }
    end
    
    schedule
  end
end
