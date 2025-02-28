class AddQuickToTags < ActiveRecord::Migration[7.1]
  def change
    add_column :tags, :quick, :boolean, default: false
  end
end
