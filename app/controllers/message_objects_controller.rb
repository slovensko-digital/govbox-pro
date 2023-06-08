class MessageObjectsController < ApplicationController
  before_action :set_message_object

  def show
    authorize @message_object
    if params[:open_action] == "download"
      send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :download
    else
      send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :inline
    end
  end

  private

  def set_message_object
    @message_object = policy_scope(MessageObject).find(params[:id])
  end

end

