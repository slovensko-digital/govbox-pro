class AddUniqueIndexesForSignings < ActiveRecord::Migration[7.0]
  def up
    remove_index :group_memberships, :group_id
    add_index :group_memberships, [:group_id, :user_id], unique: true

    execute "CREATE UNIQUE INDEX signings_tags ON tags (tenant_id, type) WHERE (type IN ('SignatureRequestedTag', 'SignedTag'));"
  end

  def down
    execute "DROP INDEX signings_tags;"

    remove_index :group_memberships, [:group_id, :user_id], unique: true
    add_index :group_memberships, :group_id
  end
end
