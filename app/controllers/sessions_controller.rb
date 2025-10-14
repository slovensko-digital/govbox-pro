class SessionsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_before_action :set_menu_context
  layout 'login'

  def login; end

  def create
    Current.user = User.find_by(email: auth_hash.info.email)

    create_session
    EventBus.publish(:user_logged_in, Current.user) if Current.user
  end

  def create_http_basic
    authenticate_or_request_with_http_basic do |email, password|
      user = User.find_by(email: email)
      Current.user = user if user&.authenticate(password)
    end

    return unless Current.user

    create_session
    EventBus.publish(:user_logged_in, Current.user)
  end

  def destroy
    EventBus.publish(:user_logged_out, User.find_by(id: session[:user_id])) if session[:user_id]

    redirect_to upvs_logout_path and return if session[:upvs_login]

    clean_session

    redirect_to root_path
  end

  def failure
    render html: "Authorization failed (#{request.params["message"]})", status: :forbidden
  end
end
