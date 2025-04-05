class CreateRecipes < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      t.string :name
      t.integer :preparation_time
      t.integer :cooking_time
      t.jsonb :instructions
      t.jsonb :nutritional_info

      t.timestamps
    end
  end
end
