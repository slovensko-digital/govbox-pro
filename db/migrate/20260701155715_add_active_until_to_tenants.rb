class AddActiveUntilToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :active_until, :datetime
  end
end
