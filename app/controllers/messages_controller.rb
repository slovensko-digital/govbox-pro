class MessagesController < ApplicationController
  before_action :set_message

  def show
    # TODO - nechceme skipovat
    skip_authorization
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end
end
