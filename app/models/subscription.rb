class Subscription < ApplicationRecord
  # Associações
  belongs_to :user
  belongs_to :plan
  has_many :transactions, dependent: :restrict_with_error
  
  # Validações
  validates :status, presence: true
  validates :mercado_pago_subscription_id, uniqueness: true, allow_nil: true
  
  # Escopos
  scope :active, -> { where(active: true) }
  scope :pending, -> { where(status: 'pending') }
  scope :canceled, -> { where.not(canceled_at: nil) }
  scope :current, -> { where('current_period_end > ?', Time.current) }
  
  # Constantes
  STATUSES = %w[pending active canceled failed].freeze
  
  # Callbacks
  before_validation :set_default_status, on: :create
  before_create :set_period_dates
  
  # Métodos de instância
  def activate!
    update(active: true, status: 'active')
  end
  
  def cancel!
    return if canceled?
    
    update(
      active: false,
      auto_renew: false,
      status: 'canceled',
      canceled_at: Time.current
    )
  end
  
  def canceled?
    canceled_at.present?
  end
  
  def active?
    active && current?
  end
  
  def current?
    current_period_end.nil? || current_period_end > Time.current
  end
  
  def expired?
    current_period_end.present? && current_period_end <= Time.current
  end
  
  def renew!(period_days = 30)
    return false unless auto_renew?
    
    new_start = [current_period_end, Time.current].max
    new_end = new_start + period_days.days
    
    update(
      current_period_start: new_start,
      current_period_end: new_end,
      active: true,
      status: 'active'
    )
  end
  
  private
  
  def set_default_status
    self.status ||= 'pending'
  end
  
  def set_period_dates
    return if current_period_start.present? && current_period_end.present?
    
    self.current_period_start = Time.current
    self.current_period_end = 30.days.from_now
  end
end
