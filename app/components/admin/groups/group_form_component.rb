class Admin::Groups::GroupFormComponent < ViewComponent::Base
  def initialize(group:, action:)
    @group = group
    @action = action
  end
end
