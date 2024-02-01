class NestedMessageObjectsController < ApplicationController
  before_action :set_nested_message_object

  def show
    authorize @nested_message_object
    send_data @nested_message_object.content, filename: MessageObjectHelper.displayable_name(@nested_message_object), type: @nested_message_object.mimetype, disposition: :inline
  end

  def download
    authorize @nested_message_object
    send_data @nested_message_object.content, filename: MessageObjectHelper.displayable_name(@nested_message_object), type: @nested_message_object.mimetype, disposition: :download
  end

  private

  def set_nested_message_object
    @nested_message_object = policy_scope(NestedMessageObject).find(params[:id])
  end
end
