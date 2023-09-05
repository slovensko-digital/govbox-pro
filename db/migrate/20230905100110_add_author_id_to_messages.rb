class AddAuthorIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :messages, :author, null: true, foreign_key: { to_table: :users }
  end
end
