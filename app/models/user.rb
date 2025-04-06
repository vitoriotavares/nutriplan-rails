class User < ApplicationRecord
  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :anamneses, dependent: :destroy
  has_many :food_plans, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :plans, through: :subscriptions
  
  validates :email, presence: true, uniqueness: true, 
                    format: { with: URI::MailTo::EMAIL_REGEXP }
                    
  # Métodos relacionados a assinaturas
  def active_subscription
    subscriptions.active.current.order(created_at: :desc).first
  end
  
  def current_plan
    active_subscription&.plan || Plan.free
  end
  
  def subscribed?
    active_subscription.present?
  end
  
  def subscribed_to?(plan)
    active_subscription&.plan_id == plan.id
  end
  
  def remaining_food_plans
    return nil if current_plan&.food_plans_limit.to_i.zero? # Plano com limite ilimitado
    
    # Calcula quantos planos o usuário já criou no período atual
    current_period_start = active_subscription&.current_period_start || Time.current.beginning_of_month
    used_plans = food_plans.where('created_at >= ?', current_period_start).count
    
    # Retorna o limite do plano mais planos adicionais comprados menos os usados
    (current_plan&.food_plans_limit.to_i + additional_food_plans) - used_plans
  end
  
  def can_create_food_plan?
    # Pode criar se tiver um plano ilimitado ou se ainda tiver planos restantes
    current_plan&.food_plans_limit.to_i.zero? || remaining_food_plans.to_i > 0
  end
  
  def add_additional_food_plans(quantity = 1)
    update(additional_food_plans: additional_food_plans + quantity)
  end
end
