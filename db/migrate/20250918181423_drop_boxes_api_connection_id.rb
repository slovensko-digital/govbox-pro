class DropBoxesApiConnectionId < ActiveRecord::Migration[7.1]
  def change
    remove_column :boxes, :api_connection_id
  end
end
