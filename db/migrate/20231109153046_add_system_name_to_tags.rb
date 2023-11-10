class AddSystemNameToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :system_name, :string

    Tag.find_each{ |tag| tag.update(system_name: tag.name) }

    change_column_null :tags, :system_name, false
  end
end
