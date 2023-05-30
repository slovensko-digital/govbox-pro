class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  def pundit_user
    Current.user
  end
end
