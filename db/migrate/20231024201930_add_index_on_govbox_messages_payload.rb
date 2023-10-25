class AddIndexOnGovboxMessagesPayload < ActiveRecord::Migration[7.0]
  def up
    execute "CREATE INDEX index_govbox_messages_on_delivery_notification_id ON govbox_messages USING HASH (((payload->'delivery_notification'->'consignment'->>'message_id')::text))"
  end

  def down
    remove_index :govbox_messages, name: :index_govbox_messages_on_delivery_notification_id
  end
end
