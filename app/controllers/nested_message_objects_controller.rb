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

  def download_pdf
    authorize @nested_message_object

    pdf_content = @nested_message_object.prepare_pdf_visualization
    if pdf_content
      send_data pdf_content, filename: MessageObjectHelper.pdf_name(@nested_message_object), type: 'application/pdf', disposition: :download
    else
      redirect_back fallback_location: message_thread_path(@nested_message_object.message.thread), notice: "Obsah nie je možné stiahnuť."
    end
  end

  private

  def set_nested_message_object
    @nested_message_object = policy_scope(NestedMessageObject).find(params[:id] || params[:nested_message_object_id])
  end
end
