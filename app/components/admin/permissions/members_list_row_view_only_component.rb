class Admin::Groups::MembersListRowViewOnlyComponent < ViewComponent::Base
  def initialize(group_membership)
    @group_membership = group_membership
    @user = @group_membership.user
  end
end
