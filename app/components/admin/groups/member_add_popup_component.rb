class Admin::Groups::MemberAddPopupComponent < ViewComponent::Base
  def initialize(users:, group:)
    @group = group
    @users = users
  end
end
