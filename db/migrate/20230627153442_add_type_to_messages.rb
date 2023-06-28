class AddTypeToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :message_type, :string, null: false
  end
end
