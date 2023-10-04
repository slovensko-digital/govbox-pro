class AddIndexToFilters < ActiveRecord::Migration[7.0]
  def change
    add_index :filters, [:tenant_id, :position], unique: true # for ordering to works all the time
  end
end
