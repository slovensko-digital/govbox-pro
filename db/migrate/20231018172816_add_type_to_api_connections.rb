class AddTypeToApiConnections < ActiveRecord::Migration[7.0]
  def change
    add_column :api_connections, :type, :string

    ApiConnection.update_all(
      type: 'Govbox::ApiConnection'
    )
  end
end
