class AddIdentifierToMessageObjects < ActiveRecord::Migration[7.1]
  def change
    add_column :message_objects, :identifier, :string, null: true
  end
end
