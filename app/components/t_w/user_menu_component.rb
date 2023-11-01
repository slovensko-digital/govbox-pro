class TW::UserMenuComponent < ViewComponent::Base
  def initialize(user:)
    @user = user
  end
end
