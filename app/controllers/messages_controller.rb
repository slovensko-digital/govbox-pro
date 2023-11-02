class MessagesController < ApplicationController
  before_action :set_message

  include MessagesConcern

  def show
    authorize @message

    @message.update(read: true)
  end

  def authorize_delivery_notification
    authorize @message

    if Message.authorize_delivery_notification(@message)
      redirect_to message_thread_path(@message.thread), notice: 'Správa bola zaradená na prevzatie'
    else
      redirect_to message_thread_path(@message.thread), alert: 'Správu nie je možné prevziať'
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
end
