class CleanExternalColumnsInTags < ActiveRecord::Migration[7.0]
  def change
    rename_column :tags, :system_name, :external_name
    remove_column :tags, :external, :boolean, default: false
  end
end
