class FoodPlan < ApplicationRecord
  belongs_to :user
  belongs_to :anamnesis, optional: true
  
  has_many :meals, dependent: :destroy
  has_one :water_plan, dependent: :destroy
  
  accepts_nested_attributes_for :meals, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :water_plan, allow_destroy: true, reject_if: :all_blank
  
  validates :name, presence: true
  validates :calories, numericality: { greater_than: 0 }, allow_nil: true
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date, if: -> { start_date.present? && end_date.present? }
  
  def duration_days
    return nil unless start_date && end_date
    
    (end_date - start_date).to_i + 1
  end
  
  def generate_grocery_list
    items = {}
    
    meals.includes(:food_items).each do |meal|
      meal.food_items.each do |item|
        if items[item.name]
          items[item.name][:quantity] += item.quantity
        else
          items[item.name] = { quantity: item.quantity, unit: item.unit }
        end
      end
    end
    
    items
  end
  
  def valid_plan?
    end_date >= Date.current
  end
  
  def days_remaining
    return 0 unless valid_plan?
    (end_date - Date.current).to_i
  end
  
  def validity_status
    if !valid_plan?
      :expired
    elsif days_remaining <= 7
      :expiring_soon
    else
      :valid
    end
  end
  
  private
  
  def end_date_after_start_date
    if end_date < start_date
      errors.add(:end_date, "deve ser posterior à data de início")
    end
  end
end
