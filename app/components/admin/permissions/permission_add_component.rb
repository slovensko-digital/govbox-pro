class Admin::Permissions::PermissionAddComponent < ViewComponent::Base
  def initialize(tag:, group:)
    @tag = tag
    @group = group
  end
end
