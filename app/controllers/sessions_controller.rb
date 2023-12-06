class SessionsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_before_action :set_menu_context
  layout 'login'

  def login
  end

  def create
    create_session
    EventBus.publish(:user_logged_in, Current.user)
  end

  def destroy
    EventBus.publish(:user_logged_out, User.find_by(id: session[:user_id]))
    clean_session

    redirect_to root_path
  end

  def failure
    render html: "Authorization failed (#{request.params["message"]})", status: :forbidden
  end
end
