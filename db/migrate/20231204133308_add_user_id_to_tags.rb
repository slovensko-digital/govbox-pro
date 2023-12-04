class AddUserIdToTags < ActiveRecord::Migration[7.0]
  def up
    add_column :tags, :user_id, :integer

    # `name` is needed because there was a `user_id` that is now `owner_id` before
    add_foreign_key :tags, :users, name: "tags_to_users"

    SignerGroup.includes(:users).find_each do |group|
      group.users.each do |user|
        SignerGroup.user_added_to_group(group, user)
      end
    end
  end

  def down
    SignerGroup.includes(:users).find_each do |group|
      group.users.each do |user|
        SignerGroup.user_removed_from_group(group, user)
      end
    end

    remove_foreign_key :tags, :users, name: "tags_to_users"

    remove_column :tags, :user_id, :integer
  end
end
