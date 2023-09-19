class Admin::Permissions::GroupsListRowComponent < ViewComponent::Base
  def initialize(group)
    @group = group
  end
end
