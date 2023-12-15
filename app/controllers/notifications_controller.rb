class NotificationsController < ApplicationController
  skip_after_action :verify_authorized

  def index
    @notifications, @next_cursor = Pagination.paginate(
      collection: Current.user.notifications,
      cursor: { id: 100000 },
    )
  end

  def scroll
    @notifications, @next_cursor = Pagination.paginate(
      collection: Current.user.notifications,
      cursor: params[:cursor],
    )
  end
end
