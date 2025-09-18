class AddSettingsToTenant < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :settings, :jsonb, null: false, default: {}
  end
end
