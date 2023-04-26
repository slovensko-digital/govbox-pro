class SessionsController < ApplicationController
  include Authenticable

  skip_before_action :authenticate_user

  def login
  end

  def create
    create_session
  end

  def destroy
    clean_session

    redirect_to root_path
  end

  def failure
    render html: "Authorization failed (#{request.params['message']})", status: :forbidden
  end

  private

  def clean_session
    session[:user_id] = nil
    session[:login_expires_at] = nil
  end
end
