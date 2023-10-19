class ChangeGovboxApiConnectionsToUpvsApiConnections < ActiveRecord::Migration[7.0]
  def change
    rename_table :govbox_api_connections, :upvs_api_connections
  end
end
