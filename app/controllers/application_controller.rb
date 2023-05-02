class ApplicationController < ActionController::Base
  before_action :authenticate_user

  # TODO fix in SAML-login PR
  def authenticate_user
    Current.subject = Subject::find(1)
  end
end
