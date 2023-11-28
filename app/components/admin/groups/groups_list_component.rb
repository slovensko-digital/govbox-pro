class Admin::Groups::GroupsListComponent < ViewComponent::Base
  def initialize(editable_groups:, non_editable_groups:)
    @editable_groups = editable_groups
    @non_editable_groups = non_editable_groups
  end
end
