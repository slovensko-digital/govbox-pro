class AddBoxIdToMessageThreads < ActiveRecord::Migration[7.0]
  def up
    add_reference :message_threads, :box, index: false, foreign_key: true, null: true

    MessageThread.select(:id, :folder_id).includes(:folder).find_each do |thread|
      MessageThread.where(id: thread.id).update_all(box_id: thread.folder.box_id) # do not change `updated_at`
    end

    change_column_null :message_threads, :box_id, false
  end

  def down
    remove_reference :message_threads, :box, foreign_key: true, index: false
  end
end
