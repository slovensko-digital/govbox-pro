class AddSystemNameToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :system_name, :string

    Tag.where("name LIKE 'slovensko.sk:%' OR name = 'Drafts'").find_each{ |tag| tag.update(system_name: tag.name) }
  end
end
