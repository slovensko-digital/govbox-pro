class AddTenantToBoxes < ActiveRecord::Migration[7.0]
  def change
    add_reference :boxes, :tenant, null: false, foreign_key: true
  end
end
