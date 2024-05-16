class DropUpvsFormMessageType < ActiveRecord::Migration[7.1]
  def up
    remove_column :upvs_forms, :message_type

    add_index :upvs_forms, [:identifier, :version], unique: true, name: :index_forms_on_identifier_version
  end
end
