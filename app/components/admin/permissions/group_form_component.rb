class Admin::Permissions::GroupFormComponent < ViewComponent::Base
  def initialize(group:)
    @group = group
  end
end
