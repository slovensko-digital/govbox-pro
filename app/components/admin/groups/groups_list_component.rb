class Admin::Groups::GroupsListComponent < ViewComponent::Base
  def initialize(editable_groups:, fixed_groups:)
    @editable_groups = editable_groups
    @fixed_groups = fixed_groups
  end
end
