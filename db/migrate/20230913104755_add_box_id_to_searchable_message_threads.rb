class AddBoxIdToSearchableMessageThreads < ActiveRecord::Migration[7.0]
  def change
    add_column :searchable_message_threads, :box_id, :integer, null: true

    ::Searchable::MessageThread.includes(message_thread: :folder).find_each do |smt|
      smt.box_id = smt.message_thread.folder.box_id
      smt.save!
    end

    change_column_null :searchable_message_threads, :box_id, false
  end
end
