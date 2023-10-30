class DropTagsUsersTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :tag_users, if_exists: true
  end
end
