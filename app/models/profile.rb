class Profile < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :height, :weight, numericality: { greater_than: 0 }, allow_nil: true
  
  enum :gender, { male: 'male', female: 'female', other: 'other' }, prefix: true
  
  def age
    return nil unless date_of_birth
    
    now = Time.current.to_date
    now.year - date_of_birth.year - (now.month > date_of_birth.month || 
                                    (now.month == date_of_birth.month && now.day >= date_of_birth.day) ? 0 : 1)
  end
  
  def bmi
    return nil unless height.present? && weight.present? && height > 0
    
    (weight / (height / 100.0) ** 2).round(2)
  end
  
  def bmi_category
    return nil unless bmi
    
    case bmi
    when 0...18.5
      'Abaixo do peso'
    when 18.5...25
      'Peso normal'
    when 25...30
      'Sobrepeso'
    when 30...35
      'Obesidade grau I'
    when 35...40
      'Obesidade grau II'
    else
      'Obesidade grau III'
    end
  end
end
