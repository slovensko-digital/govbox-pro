class MakeAuthorIdNullableInFilters < ActiveRecord::Migration[7.1]
  def change
    change_column_null :filters, :author_id, true

    remove_foreign_key :filters, :users, column: :author_id
    add_foreign_key :filters, :users, column: :author_id, on_delete: :nullify
  end
end
