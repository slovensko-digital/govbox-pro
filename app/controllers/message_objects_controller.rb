class MessageObjectsController < ApplicationController
  before_action :set_message_object

  def show
    # TODO - nechceme skipovat
    skip_authorization
    if params[:open_action] == "download"
      send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :download
    else
      send_data @message_object.message_object_datum.blob, filename: @message_object.name, type: @message_object.mimetype, disposition: :inline
    end
  end

  private

  def set_message_object
    @message_object = MessageObject.find(params[:id])
  end

end

