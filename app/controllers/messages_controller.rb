class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
  end
end
