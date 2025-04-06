class Transaction < ApplicationRecord
  # Associações
  belongs_to :user
  belongs_to :subscription
  
  # Declaração explícita do atributo transaction_type
  attribute :transaction_type, :integer, default: 0
  
  # Validações
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :mercado_pago_transaction_id, uniqueness: true, allow_nil: true
  
  # Escopos
  scope :successful, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'rejected') }
  scope :recent, -> { order(created_at: :desc) }
  
  # Tipos de transação
  enum :transaction_type, {
    subscription: 0,
    additional_plan: 1
  }, prefix: :type
  
  # Constantes
  STATUSES = %w[pending approved rejected in_process].freeze
  
  # Callbacks
  before_validation :set_default_status, on: :create
  after_save :update_subscription_status, if: -> { saved_change_to_status? && status == 'approved' }
  
  # Métodos de instância
  def approved?
    status == 'approved'
  end
  
  def pending?
    status == 'pending'
  end
  
  def rejected?
    status == 'rejected'
  end
  
  def approve!
    update(status: 'approved')
  end
  
  def reject!
    update(status: 'rejected')
  end
  
  private
  
  def set_default_status
    self.status ||= 'pending'
    self.currency ||= 'BRL'
  end
  
  def update_subscription_status
    subscription.activate! if approved?
  end
end
