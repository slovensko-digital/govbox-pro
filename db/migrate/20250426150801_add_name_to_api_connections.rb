class AddNameToApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :api_connections, :custom_name, :string
  end
end
