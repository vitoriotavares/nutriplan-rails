class Recipe < ApplicationRecord
  has_many :food_items
  has_and_belongs_to_many :food_plans
  
  validates :name, :preparation_time, :cooking_time, presence: true
  validates :preparation_time, :cooking_time, numericality: { greater_than_or_equal_to: 0 }
  
  # Definindo acessores para campos JSON
  store_accessor :instructions, :steps
  store_accessor :nutritional_info, :calories, :protein, :carbs, :fat, :fiber
  
  def total_time
    preparation_time + cooking_time
  end
  
  def difficulty
    case total_time
    when 0..15
      'Fácil'
    when 16..30
      'Médio'
    when 31..60
      'Intermediário'
    else
      'Avançado'
    end
  end
  
  def ingredients_list
    food_items.map { |item| "#{item.quantity} #{item.unit} de #{item.name}" }
  end
  
  def formatted_instructions
    return [] unless steps.is_a?(Array)
    
    steps.map.with_index(1) do |step, index|
      "#{index}. #{step}"
    end
  end
  
  def suitable_for_diet?(diet_type)
    case diet_type.to_sym
    when :vegetarian
      !food_items.any? { |item| ['carne', 'frango', 'peixe'].any? { |meat| item.name.downcase.include?(meat) } }
    when :vegan
      !food_items.any? { |item| ['carne', 'frango', 'peixe', 'leite', 'queijo', 'ovo'].any? { |animal| item.name.downcase.include?(animal) } }
    when :low_carb
      (carbs.to_f / calories.to_f) < 0.2 if carbs && calories && calories > 0
    when :high_protein
      (protein.to_f / calories.to_f) > 0.3 if protein && calories && calories > 0
    else
      true
    end
  end
end
