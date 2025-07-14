class CreateBoxesApiConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :boxes_api_connections do |t|
      t.references :box, null: false, foreign_key: true
      t.references :api_connection, null: false, foreign_key: true

      t.timestamps
    end

    add_index :boxes_api_connections, [:box_id, :api_connection_id], unique: true

    Box.find_each do |box|
      box.boxes_api_connections.find_or_create_by!(api_connection: box.api_connection)
    end
  end
end
