class AddApiConnectionReferenceToBoxes < ActiveRecord::Migration[7.0]
  def change
    add_reference :boxes, :api_connection, foreign_key: true
    add_column :boxes, :settings, :jsonb

    Box.find_each do |box|
      box_api_connection = ApiConnection.find_by(box_id: box.id)
      box.api_connection = box_api_connection
      box.settings[:obo] = box_api_connection.obo
      box.save!
    end

    remove_column :api_connections, :box_id
    remove_column :api_connections, :obo
  end
end
