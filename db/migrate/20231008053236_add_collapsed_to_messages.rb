class AddCollapsedToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :collapsed, :boolean

    change_column :messages, :collapsed, :boolean, null: false, default: false
  end
end
