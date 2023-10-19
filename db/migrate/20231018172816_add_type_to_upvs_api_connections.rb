class AddTypeToUpvsApiConnections < ActiveRecord::Migration[7.0]
  def change
    add_column :upvs_api_connections, :type, :string

    Upvs::ApiConnection.update_all(
      type: 'Govbox::ApiConnectionWithOboSupport'
    )
  end
end
