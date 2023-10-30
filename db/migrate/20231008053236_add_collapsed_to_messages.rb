class AddCollapsedToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :collapsed, :boolean
  end
end
