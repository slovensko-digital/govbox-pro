class MessageThreadsController < ApplicationController
  before_action :set_message_thread

  def show
    # TODO - nechceme skipovat
    skip_authorization
  end

  private

  def set_message_thread
    @message_thread = MessageThread.find(params[:id])
  end
end
