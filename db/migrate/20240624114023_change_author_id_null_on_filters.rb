class ChangeAuthorIdNullOnFilters < ActiveRecord::Migration[7.1]
  def change
    change_column_null :filters, :author_id, true
  end
end
