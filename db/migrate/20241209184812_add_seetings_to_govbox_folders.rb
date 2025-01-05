class AddSeetingsToGovboxFolders < ActiveRecord::Migration[7.1]
  def change
    add_column :govbox_folders, :settings, :jsonb, default: {}
  end
end
