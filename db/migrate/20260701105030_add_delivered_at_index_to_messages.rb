class AddDeliveredAtIndexToMessages < ActiveRecord::Migration[7.1]
  def change
    add_index :messages, :delivered_at
  end
end
