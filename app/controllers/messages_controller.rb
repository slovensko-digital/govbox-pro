class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @message.update(read: true)
    @message_thread = @message.thread

    @notice = notice
  end

  def reply
    authorize @message

    # TODO create temporary message

    @notice = notice
  end

  def submit_reply
    authorize @message

    permitted_params = permit_reply_params

    @reply = MessageReply.new(message: @message, title: permitted_params[:reply_title], text: permitted_params[:reply_text])

    if @reply.save
      redirect_to message_path(@message), notice: 'Správa bola zaradená na odoslanie.'
    else
      redirect_to reply_message_path(@message), notice: 'Vyplňte predmet a text odpovede.'
    end
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
