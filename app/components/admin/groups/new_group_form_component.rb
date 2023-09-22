class Admin::Groups::NewGroupFormComponent < ViewComponent::Base
  def initialize(group)
    @group = group
  end
end
