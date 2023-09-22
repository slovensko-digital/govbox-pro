class UpdateBoxReferenceInGovboxApiConnections < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :govbox_api_connections, :boxes
  end
end
