class CreateMessageThreadTags < ActiveRecord::Migration[7.0]
  def change
    create_table :message_thread_tags do |t|
      t.references :message_thread, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
