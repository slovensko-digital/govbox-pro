class ChangeQueryNullOnFilters < ActiveRecord::Migration[7.1]
  def change
    change_column_null :filters, :query, true
  end
end
