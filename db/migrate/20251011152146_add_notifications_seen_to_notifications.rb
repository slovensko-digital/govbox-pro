class AddNotificationsSeenToNotifications < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :notifications_last_seen_at, :datetime
  end
end
