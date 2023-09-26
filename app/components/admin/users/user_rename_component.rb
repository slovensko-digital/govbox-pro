class Admin::Users::UserRenameComponent < ViewComponent::Base
  def initialize(user)
    @user = user
  end
end
