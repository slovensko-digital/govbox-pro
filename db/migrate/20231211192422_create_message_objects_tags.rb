class CreateMessageObjectsTags < ActiveRecord::Migration[7.1]
  def change
    create_table :message_objects_tags do |t|
      t.references :message_object, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :message_objects_tags, [:message_object_id, :tag_id], unique: true
  end
end
