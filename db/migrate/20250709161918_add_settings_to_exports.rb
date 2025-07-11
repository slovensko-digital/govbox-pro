class AddSettingsToExports < ActiveRecord::Migration[7.1]
  def change
    add_column :exports, :settings, :jsonb, null: false, default: {}
  end
end
