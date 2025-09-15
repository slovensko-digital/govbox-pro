class CreateStickyNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :sticky_notes do |t|
      t.belongs_to :user, null: false, foreign_key: true, index: true
      t.jsonb :data
      t.string :note_type, null: false

      t.timestamps
    end
  end
end
