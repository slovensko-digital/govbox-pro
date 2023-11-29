class Admin::Groups::GroupsListComponent < ViewComponent::Base
  def initialize(editable_groups:, non_editable_groups:)
    @editable_groups = editable_groups.to_a.sort_by(&:name)
    @non_editable_groups = non_editable_groups.to_a.sort_by(&:name)
  end
end
