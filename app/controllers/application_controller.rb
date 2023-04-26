class ApplicationController < ActionController::Base
  include Authentication

  before_action :authenticate

  def current_subject
    # TODO find current subject
    Subject::find(1)
  end
end
