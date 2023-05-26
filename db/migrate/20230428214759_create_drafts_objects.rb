class CreateDraftsObjects < ActiveRecord::Migration[7.0]
  def change
    create_table :drafts_objects do |t|
      t.references :draft, null: false, foreign_key: true

      t.uuid :uuid, null: false
      t.string :name, null: false
      t.boolean :signed
      t.boolean :to_be_signed
      t.boolean :form

      t.timestamps
    end
  end
end
