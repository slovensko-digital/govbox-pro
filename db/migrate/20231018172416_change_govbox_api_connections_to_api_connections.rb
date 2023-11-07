class ChangeGovboxApiConnectionsToApiConnections < ActiveRecord::Migration[7.0]
  def change
    rename_table :govbox_api_connections, :api_connections
  end
end
