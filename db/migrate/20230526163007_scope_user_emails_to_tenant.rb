class ScopeUserEmailsToTenant < ActiveRecord::Migration[7.0]
  def change
    remove_index :users, :email, unique: true
    add_index :users, [:tenant_id, :email], unique: true
    remove_index :users, :tenant_id # covered by index above
  end
end
