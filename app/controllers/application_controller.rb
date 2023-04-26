class ApplicationController < ActionController::Base
  include Authentication

  before_action :authenticate

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  helper_method :current_user

  def current_subject
    # TODO find current subject
    Subject::find(1)
  end
end
