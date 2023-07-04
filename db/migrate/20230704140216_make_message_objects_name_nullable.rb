class MakeMessageObjectsNameNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :message_objects, :name, true
  end
end
