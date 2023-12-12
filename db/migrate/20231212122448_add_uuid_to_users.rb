class AddUuidToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :uuid, :uuid
  end
end
