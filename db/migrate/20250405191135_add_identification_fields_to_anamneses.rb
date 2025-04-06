class AddIdentificationFieldsToAnamneses < ActiveRecord::Migration[8.0]
  def change
    add_column :anamneses, :title, :string
    add_column :anamneses, :client_name, :string
  end
end
