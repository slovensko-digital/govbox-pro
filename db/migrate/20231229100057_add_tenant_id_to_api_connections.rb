class AddTenantIdToApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_reference :api_connections, :tenant, index: true, foreign_key: true, null: true
  end
end
