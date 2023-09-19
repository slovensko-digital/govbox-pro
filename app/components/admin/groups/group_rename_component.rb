class Admin::Groups::GroupRenameComponent < ViewComponent::Base
  def initialize(group)
    @group = group
  end
end
