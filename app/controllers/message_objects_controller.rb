class MessageObjectsController < ApplicationController
  before_action :set_message_object

  def show
    authorize @message_object
    send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :inline
  end

  def download
    authorize @message_object
    send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :download
  end

  private

  def set_message_object
    @message_object = policy_scope(MessageObject).find(params[:id])
  end
end
