class AddNotificationsSeenToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notifications_opened, :boolean, default: false, null: false
  end
end
