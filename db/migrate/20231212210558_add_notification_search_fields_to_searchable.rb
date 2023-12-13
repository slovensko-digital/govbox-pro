class AddNotificationSearchFieldsToSearchable < ActiveRecord::Migration[7.1]
  def change
    change_table :searchable_message_threads, bulk: true do |t|
      t.column :last_message_created_at, :datetime
      t.column :message_thread_updated_at, :datetime
      t.column :message_thread_note_updated_at, :datetime
    end

    Searchable::MessageThread.reindex_all

    change_column_null :searchable_message_threads, :last_message_created_at, false
    change_column_null :searchable_message_threads, :message_thread_updated_at, false
  end
end
