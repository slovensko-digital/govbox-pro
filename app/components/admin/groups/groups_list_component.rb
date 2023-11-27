class Admin::Groups::GroupsListComponent < ViewComponent::Base
  def initialize(modifiable_groups:, fixed_groups:)
    @modifiable_groups = modifiable_groups
    @fixed_groups = fixed_groups
  end
end
