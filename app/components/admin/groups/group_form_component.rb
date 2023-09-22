class Admin::Groups::GroupFormComponent < ViewComponent::Base
  def initialize(group:, step:)
    @group = group
    @step = step
  end
end
