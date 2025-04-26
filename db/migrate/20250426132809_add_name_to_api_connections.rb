class AddNameToApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :api_connections, :name, :string
  end
end
