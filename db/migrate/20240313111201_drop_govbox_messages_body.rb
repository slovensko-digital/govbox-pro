class DropGovboxMessagesBody < ActiveRecord::Migration[7.1]
  def change
    remove_column :govbox_messages, :body
  end
end
