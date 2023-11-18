class AllowNilInMessageThreadsFolderId < ActiveRecord::Migration[7.0]
  def up
    change_column_null :message_threads, :folder_id, true
  end

  def down
    # this is irreversible
  end
end
