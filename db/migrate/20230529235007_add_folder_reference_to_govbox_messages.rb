class AddFolderReferenceToGovboxMessages < ActiveRecord::Migration[7.0]
  def change
    add_reference :govbox_messages, :folder, null: false, foreign_key: { to_table: :govbox_folders }
  end
end
