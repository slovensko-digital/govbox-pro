class CreateSearchableMessageThreads < ActiveRecord::Migration[7.0]
  def change
    create_table :searchable_message_threads do |t|
      t.integer :message_thread_id, null: false
      t.text :title, null: false
      t.text :content, null: false
      t.text :tag_names, null: false
      t.integer :tag_ids, array: true, default: [], null: false
      t.datetime :last_message_delivered_at, null: false

      t.timestamps null: false
    end

    add_index :searchable_message_threads, :message_thread_id, unique: true
    add_foreign_key :searchable_message_threads, :message_threads, on_delete: :cascade
  end
end
