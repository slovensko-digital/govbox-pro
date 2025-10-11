class DropBoxesOtherApiConnections < ActiveRecord::Migration[7.1]
  def up
    drop_table :boxes_other_api_connections
  end
end
