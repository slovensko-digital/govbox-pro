class MessagesController < ApplicationController
  before_action :set_message

  include MessagesConcern

  def show
    authorize @message

    @mode = params[:mode].to_sym
    @collapsed = params[:collapsed] == 'true'
    @message.update(read: true)
  end

  def update
    authorize @message
    return unless @message.update(message_update_params)

    redirect_back fallback_location: messages_path(@message)
  end

  def authorize_delivery_notification
    authorize @message

    @message.transaction do
      if Govbox::AuthorizeDeliveryNotificationAction.run(@message)
        EventBus.publish(:message_delivery_authorized, @message)
        redirect_to message_thread_path(@message.thread), notice: 'Správa bola zaradená na prevzatie'
      else
        redirect_to message_thread_path(@message.thread), alert: 'Správu nie je možné prevziať'
      end
    end
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
    set_visible_tags_for_thread
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end

  def message_update_params
    params.permit(:collapsed)
  end
end
