class CreateFoodPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :food_plans do |t|
      t.references :user, null: false, foreign_key: true
      # Removendo temporariamente a referência à tabela anamneses
      # t.references :anamnesis, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.date :start_date
      t.date :end_date
      t.integer :calories

      t.timestamps
    end
  end
end
