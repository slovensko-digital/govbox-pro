class AddEdeskMessageIdToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :govbox_messages, :edesk_message_id, :bigint, null: false
  end
end
