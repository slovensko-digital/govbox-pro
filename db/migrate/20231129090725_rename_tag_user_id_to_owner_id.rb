class RenameTagUserIdToOwnerId < ActiveRecord::Migration[7.0]
  def change
    rename_column :tags, :user_id, :owner_id
  end
end
