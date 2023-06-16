class CreateTags < ActiveRecord::Migration[7.0]
  def change
    def change
      create_table :tags do |t|
        t.belongs_to :box, null: false, foreign_key: true
        t.string :name, null: false

        t.timestamps
      end
    end
  end
end
