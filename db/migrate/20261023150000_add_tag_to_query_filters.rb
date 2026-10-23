class AddTagToQueryFilters < ActiveRecord::Migration[8.1]
  def change
    add_reference :filters, :tag, foreign_key: { on_delete: :nullify }
  end
end
