class Admin::Users::UserFormComponent < ViewComponent::Base
  def initialize(user:, action:)
    @user = user
    @action = action
  end
end
