class AddTagToFilters < ActiveRecord::Migration[7.1]
  def change
    add_reference :filters, :tag, null: true, foreign_key: true
  end
end
