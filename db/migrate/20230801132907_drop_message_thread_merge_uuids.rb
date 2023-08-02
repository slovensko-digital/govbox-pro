class DropMessageThreadMergeUuids < ActiveRecord::Migration[7.0]
  def change
    remove_column :message_threads, :merge_uuids
  end
end
