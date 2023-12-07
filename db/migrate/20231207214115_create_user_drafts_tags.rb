class CreateUserDraftsTags < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      user.tenant.tags.find_or_create_by!(
        owner: user,
        name: "Drafts-#{user.name}",
        type: "DraftTag",
        visible: false
      )
    end
  end
end
