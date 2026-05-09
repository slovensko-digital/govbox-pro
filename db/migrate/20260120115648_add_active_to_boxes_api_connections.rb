class AddActiveToBoxesApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :boxes_api_connections, :active, :boolean, default: true, null: false
  end
end
