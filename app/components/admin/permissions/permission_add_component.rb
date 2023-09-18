class Admin::Permissions::PermissionAddComponent < ViewComponent::Base
  def initialize(tag:, group:)
    @tag = tag
    @group = group
    @new_permission = TagGroup.new({ group_id: @group.id, tag_id: @tag.id })
  end
end
