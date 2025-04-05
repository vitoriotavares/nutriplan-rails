class CreateProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.date :date_of_birth
      t.string :gender
      t.float :height
      t.float :weight

      t.timestamps
    end
  end
end
