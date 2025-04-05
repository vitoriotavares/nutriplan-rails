class User < ApplicationRecord
  has_secure_password
  has_one :profile, dependent: :destroy
  has_many :anamneses, dependent: :destroy
  has_many :food_plans, dependent: :destroy
  
  validates :email, presence: true, uniqueness: true, 
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
