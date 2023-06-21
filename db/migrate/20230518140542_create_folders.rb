class CreateFolders < ActiveRecord::Migration[7.0]
  def change
    create_table :folders do |t|
      t.belongs_to :box, null: false, foreign_key: true
      t.string :name, null: false

      t.timestamps
    end
  end
end
