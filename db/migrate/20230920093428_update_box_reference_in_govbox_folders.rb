class UpdateBoxReferenceInGovboxFolders < ActiveRecord::Migration[7.0]
  def change
    remove_foreign_key :govbox_folders, :boxes
  end
end
