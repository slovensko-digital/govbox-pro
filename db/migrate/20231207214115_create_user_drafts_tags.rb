class CreateUserDraftsTags < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      draft_tag = user.tenant.tags.find_or_create_by!(
        owner: user,
        name: "Drafts-#{user.name}",
        type: "DraftTag",
        visible: false
      )

      user_group = user.groups.where(type: "UserGroup")
      draft_tag.mark_readable_by_groups(user_group)
    end
  end
end
