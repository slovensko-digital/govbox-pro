class CreateArchivedObjectVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :archived_object_versions do |t|
      t.belongs_to :archived_object, null: false, foreign_key: true
      t.binary :content, null: false
      t.string :validation_result
      t.datetime :valid_to, null: false

      t.timestamps
    end
  end
end
