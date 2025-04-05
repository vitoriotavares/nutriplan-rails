class CreateAnamneses < ActiveRecord::Migration[8.0]
  def change
    create_table :anamneses do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :health_data
      t.jsonb :dietary_preferences
      t.jsonb :restrictions
      t.jsonb :lifestyle
      t.jsonb :goals

      t.timestamps
    end
  end
end
