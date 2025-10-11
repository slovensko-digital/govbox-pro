class NotificationsController < ApplicationController
  skip_after_action :verify_authorized

  before_action :set_notifications_and_cursor
  before_action :set_retention

  def index
  end

  def scroll
  end

  def badge
    render partial: "notifications/badge", locals: { user: Current.user }
  end

  private

  def set_notifications_and_cursor
    @notifications, @next_cursor = Pagination.paginate(
      collection: Current.user.notifications.includes(:message_thread, :message, :export, filter_subscription: :filter),
      cursor: params[:cursor]&.permit(:id).to_h.presence || { id: nil },
      items_per_page: 20
    )
    @next_page_params = {
      cursor: @next_cursor,
      format: :turbo_stream
    }
  end

  def set_retention
    Current.user.update_notifications_retention

    @last_opened_at = Current.user.notifications_last_opened_at || -DateTime::Infinity.new
  end
end
