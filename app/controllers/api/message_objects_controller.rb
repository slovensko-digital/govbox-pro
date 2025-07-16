class Api::MessageObjectsController < Api::TenantController
  def pdf
    @message_object = @tenant.messages.includes(:objects).find_by(objects: { id: params[:message_object_id] || params[:id] }).objects.take
    @pdf_content = @message_object.prepare_pdf_visualization

    if @pdf_content
      EventBus.publish(:message_object_downloaded, @message_object)

      send_data @pdf_content, filename: MessageObjectHelper.pdf_name(@message_object), type: 'application/pdf', disposition: :download
    else
      render_not_found
    end
  end
end
