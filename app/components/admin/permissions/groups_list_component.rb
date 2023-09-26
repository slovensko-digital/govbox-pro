class Admin::Permissions::GroupsListComponent < ViewComponent::Base
  def initialize(groups)
    @groups = groups
  end
end
