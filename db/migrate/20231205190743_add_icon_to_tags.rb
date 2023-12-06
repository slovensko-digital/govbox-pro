class AddIconToTags < ActiveRecord::Migration[7.0]
  def change
    add_column :tags, :icon, :string
  end
end
