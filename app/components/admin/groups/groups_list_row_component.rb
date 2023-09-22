class Admin::Groups::GroupsListRowComponent < ViewComponent::Base
  def initialize(group)
    @group = group
  end
end
