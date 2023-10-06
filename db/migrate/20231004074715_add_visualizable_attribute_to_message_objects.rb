class AddVisualizableAttributeToMessageObjects < ActiveRecord::Migration[7.0]
  def change
    add_column :message_objects, :visualizable, :boolean
  end
end
