class AddEdeskDeliveryToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :govbox_messages, :delivered_at, :datetime, null: false
  end
end
