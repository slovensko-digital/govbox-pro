class UpdateTagsUniqueNameConstraint < ActiveRecord::Migration[7.1]
  def change
    remove_index :tags, name: "index_tags_on_tenant_id_and_type_and_lowercase_name"
    add_index :tags, [:tenant_id, :type, :name], unique: true
  end
end
