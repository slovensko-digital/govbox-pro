class DropTagsUsersTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :tag_users
  end
end
