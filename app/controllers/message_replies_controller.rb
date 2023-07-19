class MessageRepliesController < ApplicationController
  before_action :set_message
  before_action :set_message_reply, only: [:submit, :show]

  def create
    authorize @message

    @message_reply = MessageReply.create_from_message(@message)

    redirect_to message_reply_path(@message, @message_reply)
  end

  def show
    authorize @message_reply
    @notice = notice
  end

  def submit
    authorize @message

    permitted_params = permit_reply_params

    @reply = MessageReply.find(params[:id])
    if @reply.save
      redirect_to message_path(@message), notice: "Správa bola zaradená na odoslanie."
    else
      redirect_to message_reply_path(@message_reply), notice: "Vyplňte predmet a text odpovede."
    end
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:message_id])
  end

  def set_message_reply
    @message_reply = MessageReply.find(params[:id])
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
