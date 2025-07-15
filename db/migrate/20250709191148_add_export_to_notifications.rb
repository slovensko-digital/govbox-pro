class AddExportToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_belongs_to :notifications, :export
    change_column_null :notifications, :filter_name, true
    change_column_null :notifications, :message_thread_id, true
  end
end
