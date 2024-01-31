class AllowOnlyUniqueCombinationsOfApiConnectionIdAndBoxSettingsObo < ActiveRecord::Migration[7.1]
  def up
    execute "CREATE UNIQUE INDEX api_connection_box_settings_obo ON boxes( tenant_id, api_connection_id, (settings->>'obo') ) ;"
  end

  def down
    remove_index :boxes, name: "api_connection_box_settings_obo"
  end
end
