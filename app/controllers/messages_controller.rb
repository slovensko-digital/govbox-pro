class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @message.update(read: true)
    @message_thread = @message.thread

    @notice = notice
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
    @menu = SidebarMenu.new(controller_name, action_name, { message: @message })
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
