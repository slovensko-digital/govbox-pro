class CreateFilters < ActiveRecord::Migration[7.0]
  def change
    create_table :filters do |t|
      t.references :user, null: false
      t.string :name, null: false
      t.string :query, null: false
      t.integer :position, null: false

      t.timestamps
    end

    add_foreign_key :filters, :users, on_delete: :cascade
  end
end
