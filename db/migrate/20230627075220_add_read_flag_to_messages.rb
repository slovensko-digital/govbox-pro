class AddReadFlagToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :read, :boolean, default: false, null: false
  end
end
