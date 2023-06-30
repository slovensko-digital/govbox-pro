class SessionsController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped
  skip_before_action :set_menu_context

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
end
