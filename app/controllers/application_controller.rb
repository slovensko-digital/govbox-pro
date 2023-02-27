class ApplicationController < ActionController::Base
  def subject
    # TODO current subject
    Subject::find(1)
  end
end
