class Admin::Permissions::PermissionsListRowComponent < ViewComponent::Base
  def initialize(tag_group)
    @tag_group = tag_group
    @tag = @tag_group.tag
  end
end
