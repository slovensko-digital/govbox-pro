class AddImportIdToMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :messages, :import, null: true, foreign_key: { to_table: :message_drafts_imports }
  end
end
