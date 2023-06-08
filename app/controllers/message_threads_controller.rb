class MessageThreadsController < ApplicationController
  before_action :set_message_thread

  def show
    authorize @message_thread
  end

  private

  def set_message_thread
    @message_thread = policy_scope(MessageThread).find(params[:id])
  end
end
