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
  
  # Serializar o campo substitutes como um array de hashes
  serialize :substitutes, coder: JSON
  
  # Método para processar os atributos dos substitutos
  def substitutes_attributes=(attributes)
    self.substitutes ||= []
    
    # Limpar substitutos existentes se estiver recebendo novos
    self.substitutes = [] if attributes.present?
    
    # Processar cada substituto
    attributes.each do |_key, substitute_params|
      next if substitute_params.values.all?(&:blank?)
      
      # Adicionar o novo substituto
      self.substitutes << {
        name: substitute_params[:name],
        quantity: substitute_params[:quantity],
        unit: substitute_params[:unit]
      }
    end
  end
  
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
  
  # Adicionar um substituto
  def add_substitute(name, quantity, unit)
    substitute = {
      name: name,
      quantity: quantity,
      unit: unit
    }
    
    self.substitutes ||= []
    self.substitutes << substitute
    substitute
  end
  
  # Verificar se o item tem substitutos
  def has_substitutes?
    # Garantir que substitutes não seja nil e tenha pelo menos um item
    !substitutes.nil? && substitutes.is_a?(Array) && substitutes.any?
  end
  
  # Formatar os substitutos para exibição
  def substitutes_text
    return nil unless has_substitutes?
    
    substitutes.map do |sub|
      "#{sub["name"] || sub[:name]} - #{sub["quantity"] || sub[:quantity]} #{sub["unit"] || sub[:unit]}"
    end.join(" ou ")
  end
end
