class CreateGovboxFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :govbox_folders do |t|
      t.integer :edesk_folder_id, null: false
      t.integer :edesk_parent_folder_id
      t.string :name, null: false
      t.boolean :system, null: false
      t.references :box, null: false, foreign_key: true

      t.timestamps
    end

    add_index :govbox_folders, :edesk_folder_id, unique: true
  end
end
