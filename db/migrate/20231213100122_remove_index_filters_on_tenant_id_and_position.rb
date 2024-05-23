class RemoveIndexFiltersOnTenantIdAndPosition < ActiveRecord::Migration[7.1]
  def change
    remove_index :filters, [:tenant_id, :position], unique: true
  end
end
