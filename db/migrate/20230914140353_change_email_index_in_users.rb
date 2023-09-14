class ChangeEmailIndexInUsers < ActiveRecord::Migration[7.0]
  def up
    remove_index :users, name: "index_users_on_tenant_id_and_email"
    execute "CREATE UNIQUE INDEX index_users_on_tenant_id_and_lowercase_email ON users USING btree (tenant_id, lower(email));"
  end

  def down
    remove_index :users, name: "index_users_on_tenant_id_and_lowercase_email"
    add_index :users, [:tenant_id, :email], unique: true, name: "index_users_on_tenant_id_and_email"
  end
end
