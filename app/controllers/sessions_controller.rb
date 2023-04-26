class SessionsController < ApplicationController
  skip_before_action :authenticate

  def login
  end

  def create
    auth = request.env["omniauth.auth"]

    user = User.find_or_create_by!(email: auth.info.email)
    cookies.encrypted[:user_id] = user.id

    binding.pry

    redirect_to root_path
  end

  def destroy
    cookies.encrypted[:user_id] = nil
    redirect_to root_path
  end
end
