class AddSettingsToApiConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :api_connections, :settings, :jsonb
  end
end
