class AddLastMessageDeliveredAtToMessageThreads < ActiveRecord::Migration[7.0]
  def change
    add_column :message_threads, :last_message_delivered_at, :datetime

    MessageThread.find_each do |message_thread|
      last_message_delivered_at = message_thread.messages.order(:delivered_at).last.delivered_at
      message_thread.update(
        last_message_delivered_at: last_message_delivered_at
      )
    end

    change_column :message_threads, :last_message_delivered_at, :datetime, null: false
  end
end
