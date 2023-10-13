class CreateMessageThreadNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :message_thread_notes do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.text :note
      t.timestamps
    end
  end
end
