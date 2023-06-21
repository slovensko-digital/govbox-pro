class MakeMessageRecipientNameSenderNameNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :messages, :sender_name, true
    change_column_null :messages, :recipient_name, true
  end
end
