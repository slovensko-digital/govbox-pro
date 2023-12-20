class DestroyOldNotifications < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :notifications, :messages
    add_foreign_key :notifications, :messages, on_delete: :cascade

    remove_foreign_key :notifications, :message_threads
    add_foreign_key :notifications, :message_threads, on_delete: :cascade

    remove_foreign_key :notifications, :filter_subscriptions
    add_foreign_key :notifications, :filter_subscriptions, on_delete: :cascade

    remove_foreign_key :notifications, :users
    add_foreign_key :notifications, :users, on_delete: :cascade
  end
end
