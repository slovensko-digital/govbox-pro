class CreateArchivedObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :archived_objects do |t|
      t.belongs_to :message_object, null: false, foreign_key: true
      t.string :validation_result, null: false
      t.string :signed_by
      t.datetime :signed_at
      t.string :signature_level

      t.timestamps
    end
  end
end
