class NotificationsController < ApplicationController
  skip_after_action :verify_authorized
  def index
    @notifications = Current.user.notifications.order(id: :desc)
  end
end
