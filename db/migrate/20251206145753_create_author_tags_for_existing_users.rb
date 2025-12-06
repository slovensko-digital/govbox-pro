class CreateAuthorTagsForExistingUsers < ActiveRecord::Migration[7.1]
  def up
    User.find_each do |user|
      next if user.author_tag.present?

      ActiveRecord::Base.transaction do
        user_group = user.user_group

        author_tag = user.tenant.tags.create!(
          owner: user,
          name: "Authors-#{user.name}",
          type: "AuthorTag",
          visible: false
        )
        author_tag.mark_readable_by_groups([user_group])
      end
    end
  end

  def down
    Tag.where(type: "AuthorTag").destroy_all
  end
end
