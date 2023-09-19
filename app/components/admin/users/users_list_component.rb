class Admin::Users::UsersListComponent < ViewComponent::Base
  def initialize(users)
    @users = users
  end
end
