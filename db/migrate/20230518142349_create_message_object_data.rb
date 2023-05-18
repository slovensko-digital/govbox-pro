class CreateMessageObjectData < ActiveRecord::Migration[7.0]
  def change
    create_table :message_object_data do |t|
      t.belongs_to :message_object, null: false, foreign_key: true
      t.text :blob, null: false

      t.timestamps
    end
  end
end
