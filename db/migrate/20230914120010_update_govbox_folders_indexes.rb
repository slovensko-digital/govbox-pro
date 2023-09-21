class UpdateGovboxFoldersIndexes < ActiveRecord::Migration[7.0]
  def change
    remove_index :govbox_folders, :edesk_folder_id, unique: true
    add_index :govbox_folders, [:edesk_folder_id, :box_id], unique: true
  end
end
