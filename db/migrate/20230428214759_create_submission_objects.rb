class CreateSubmissionObjects < ActiveRecord::Migration[7.0]
  def change
    create_table :submissions_objects do |t|
      t.references :submission, null: false, foreign_key: true

      t.uuid :uuid, null: false
      t.string :name, null: false
      t.boolean :signed
      t.boolean :to_be_signed
      t.boolean :form

      t.timestamps
    end
  end
end
