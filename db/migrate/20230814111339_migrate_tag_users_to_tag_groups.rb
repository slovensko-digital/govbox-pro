class MigrateTagUsersToTagGroups < ActiveRecord::Migration[7.0]
  def change
    User.transaction do
      User.find_each do |user|
        user_group = user.groups.find_by_name!(user.name)

        user_group.tag_ids = user.tag_ids
      end
    end
  end
end
