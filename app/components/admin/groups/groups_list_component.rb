class Admin::Groups::GroupsListComponent < ViewComponent::Base
  def initialize(custom_groups:, system_groups:)
    @custom_groups = custom_groups
    @system_groups = system_groups
  end
end
