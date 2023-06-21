class AddPayloadToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :govbox_messages, :payload, :json, null: false
  end
end
