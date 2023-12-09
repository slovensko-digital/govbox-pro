class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :type, null: false
      t.belongs_to :user, null: false, foreign_key: true
      t.belongs_to :message_thread, null: false, foreign_key: true
      t.belongs_to :message, foreign_key: true
      t.datetime :happened_at, null: false

      t.timestamps
    end
  end
end
