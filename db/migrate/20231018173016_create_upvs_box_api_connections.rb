class CreateUpvsBoxApiConnections < ActiveRecord::Migration[7.0]
  def up
    create_table :upvs_box_api_connections do |t|
      t.belongs_to :box, null: false, foreign_key: true, on_delete: :cascade
      t.belongs_to :api_connection, null: false, foreign_key: { to_table: :upvs_api_connections }, on_delete: :cascade

      t.uuid :obo

      t.timestamps
    end

    Upvs::ApiConnection.find_each do |api_connection|
      Upvs::BoxApiConnection.find_or_create_by!(
        box_id: api_connection.box_id,
        api_connection: api_connection,
        obo: api_connection.obo
      )
    end

    remove_reference :upvs_api_connections, :box
    remove_column :upvs_api_connections, :obo
  end
end
