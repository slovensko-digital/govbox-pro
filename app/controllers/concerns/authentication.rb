module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate
  end

  private

  def authenticate
    authenticated_user = User.find_by(id: cookies.encrypted[:user_id])

    if authenticated_user
      Current.user = authenticated_user
    else
      redirect_to root_path
    end
  end
end
