class ApplicationController < ActionController::Base
  def current_subject
    # TODO find current subject
    Subject::find(1)
  end
end
