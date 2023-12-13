class UpdateUniqueNameIndexOnTags < ActiveRecord::Migration[7.1]
  def up
    remove_index :tags, name: "index_tags_on_tenant_id_and_lowercase_name"
    execute "CREATE UNIQUE INDEX index_tags_on_tenant_id_and_type_and_lowercase_name ON tags USING btree (tenant_id, type, lower(name));"
  end

  def down
    remove_index :tags, name: "index_tags_on_tenant_id_and_type_and_lowercase_name"
    execute "CREATE UNIQUE INDEX index_tags_on_tenant_id_and_lowercase_name ON tags USING btree (tenant_id, lower(name));"
  end
end
