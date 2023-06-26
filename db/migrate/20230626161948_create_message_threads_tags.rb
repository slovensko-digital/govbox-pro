class CreateMessageThreadsTags < ActiveRecord::Migration[7.0]
  def change
    create_table :message_threads_tags do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :message_threads_tags, [:message_thread_id, :tag_id], unique: true
  end
end
