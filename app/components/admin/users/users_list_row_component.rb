class Admin::Users::UsersListRowComponent < ViewComponent::Base
  def initialize(user)
    @user = user
  end
end
