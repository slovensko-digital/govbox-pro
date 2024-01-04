class AddNotificationsTimestampsToUser < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      t.column :notifications_last_opened_at, :datetime
      t.column :notifications_reset_at, :datetime
    end
  end
end
