class AddOwnerToApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_reference :api_connections, :owner, index: true, foreign_key: { to_table: :users }, null: true
  end
end
