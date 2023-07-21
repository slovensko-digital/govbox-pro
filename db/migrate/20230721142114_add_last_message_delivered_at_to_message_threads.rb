class AddLastMessageDeliveredAtToMessageThreads < ActiveRecord::Migration[7.0]
  def change
    add_column :message_threads, :last_message_delivered_at, :datetime, null: false
  end
end
