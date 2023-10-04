class MakeMessageObjectsMimeTypeNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :message_objects, :mimetype, true
  end
end
