class AddSettingsToBoxesOtherApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :boxes_other_api_connections, :settings, :jsonb, default: {}
  end
end
