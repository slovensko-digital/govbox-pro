class CreateBoxes < ActiveRecord::Migration[7.0]
  def change
    create_table :boxes do |t|
      t.string :name, null: false
      t.string :uri, null: false

      t.timestamps
    end
  end
end
