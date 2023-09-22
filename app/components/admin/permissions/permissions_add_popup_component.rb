class Admin::Permissions::PermissionsAddPopupComponent < ViewComponent::Base
  def initialize(tags:, group:)
    @group = group
    @tags = tags
  end
end
