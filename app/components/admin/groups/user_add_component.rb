class Admin::Groups::UserAddComponent < ViewComponent::Base
  def initialize(user:, group:)
    @user = user
    @group = group
    @new_membership = GroupMembership.new({ user_id: @user.id, group_id: @group.id })
  end
end
