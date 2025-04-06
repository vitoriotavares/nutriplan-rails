class Plan < ApplicationRecord
  # Associações
  has_many :subscriptions, dependent: :restrict_with_error
  has_many :users, through: :subscriptions
  
  # Validações
  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :food_plans_limit, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # Escopos
  scope :active, -> { where(active: true) }
  scope :default, -> { where(is_default: true) }
  
  # Callbacks
  before_save :ensure_only_one_default
  
  # Métodos de classe
  def self.free
    find_by(price: 0)
  end
  
  def self.premium
    where("price > 0").order(price: :asc).first
  end
  
  def self.default_plan
    default.first || active.order(price: :asc).first
  end
  
  # Métodos de instância
  def free?
    price.zero?
  end
  
  # Métodos privados
  private
  
  def ensure_only_one_default
    return unless is_default?
    
    Plan.where.not(id: id).update_all(is_default: false) if is_default_changed? && is_default?
  end
end
