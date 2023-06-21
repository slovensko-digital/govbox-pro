class CreateMessageObjects < ActiveRecord::Migration[7.0]
  def change
    create_table :message_objects do |t|
      t.belongs_to :message, null: false, foreign_key: true
      t.string :name, null: false
      t.string :mimetype, null: false
      t.string :type, null: false

      t.timestamps
    end
  end
end
