class CreateSubjects < ActiveRecord::Migration[7.0]
  def change
    create_table :subjects do |t|
      t.references :tenant, null: false, foreign_key: true

      t.string :name
      t.string :uri
      t.string :sub

      t.timestamps
    end
  end
end
