class AddIcoToTenants < ActiveRecord::Migration[7.1]
  def change
    add_column :tenants, :ico, :string, limit: 8
  end
end
