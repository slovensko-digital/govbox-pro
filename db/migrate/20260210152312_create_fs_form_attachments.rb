class CreateFsFormAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :fs_form_attachment_groups do |t|
      t.string :identifier, null: false
      t.string :name
      t.text :mime_types, array: true, default: []

      t.timestamps
    end

    add_index :fs_form_attachment_groups, :identifier, unique: true

    create_table :fs_form_attachments do |t|
      t.integer :min_occurrences, null: false, default: 0
      t.integer :max_occurrences, null: false, default: 99
      t.references :fs_form, null: false, foreign_key: true
      t.references :fs_form_attachment_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
