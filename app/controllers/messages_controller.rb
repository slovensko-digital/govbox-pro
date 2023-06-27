class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message
    @message.update(read: true)
    @message_thread = @message.thread
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
  end
end
