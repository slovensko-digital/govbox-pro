class CreateNestedMessageObjects < ActiveRecord::Migration[7.0]
  def change
    create_table :nested_message_objects do |t|
      t.string :name
      t.string :mimetype
      t.binary :content, null: false
      t.references :message_object, null: false

      t.timestamps
    end

    add_foreign_key :nested_message_objects, :message_objects, on_delete: :cascade
  end
end
