class AddDescriptionToMessageObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :message_objects, :description, :string
  end
end
