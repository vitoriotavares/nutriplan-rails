class FoodItem < ApplicationRecord
  belongs_to :meal
  
  validates :name, :quantity, :unit, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  
  # Atributos nutricionais adicionais
  attribute :calories, :float
  attribute :protein, :float
  attribute :carbs, :float
  attribute :fat, :float
  
  # Unidades comuns
  UNITS = %w[g ml colher_sopa colher_cha xicara unidade fatia]
  
  def display_quantity
    "#{quantity} #{unit}"
  end
  
  def nutritional_info
    {
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat
    }
  end
end
