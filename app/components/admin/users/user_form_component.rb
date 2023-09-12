class Admin::Users::UserFormComponent < ViewComponent::Base
  def initialize(user)
    @user = user
  end
end
