class CreateBoxesApiConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :boxes_api_connections do |t|
      t.references :box, null: false, foreign_key: true
      t.references :api_connection, null: false, foreign_key: true

      t.timestamps
    end

    add_index :boxes_api_connections, [:box_id, :api_connection_id], unique: true
  end
end
