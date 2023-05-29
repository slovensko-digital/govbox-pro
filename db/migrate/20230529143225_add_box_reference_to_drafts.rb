class AddBoxReferenceToDrafts < ActiveRecord::Migration[7.0]
  def change
    add_reference :drafts_imports, :box, null: false, foreign_key: true
    add_reference :drafts, :box, null: false, foreign_key: true
  end
end
