class MessageObjectsController < ApplicationController
  before_action :set_message_object, except: :create
  before_action :set_message, only: [:create, :update, :destroy, :signing_data]

  def create
    authorize @message

    MessageObject.create_message_objects(@message, params[:attachments])

    render partial: 'list'
  end

  def update
    authorize @message_object

    mark_message_object_as_signed(@message_object)
    
    last_thread_message_draft = @message.thread.message_drafts.includes(objects: :nested_message_objects, attachments: :nested_message_objects).order(delivered_at: :asc)&.last
    @is_last = @message == last_thread_message_draft
  end

  def show
    authorize @message_object
    send_data @message_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :inline
  end

  def download
    authorize @message_object

    EventBus.publish(:message_object_downloaded, @message_object)

    send_data @message_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :download
  end

  def download_pdf
    authorize @message_object

    pdf_content = @message_object.prepare_pdf_visualization
    if pdf_content
      EventBus.publish(:message_object_downloaded, @message_object)

      send_data pdf_content, filename: MessageObjectHelper.pdf_name(@message_object), type: 'application/pdf', disposition: :download
    else
      redirect_back fallback_location: message_thread_path(@message_object.message.thread), alert: "Obsah nie je možné stiahnuť."
    end
  end

  def download_archived
    authorize @message_object
    send_data @message_object.archived_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :download
  end

  def signing_data
    authorize @message_object

    head :no_content and return unless @message_object.content.present?
    
    return unless @message_object.form?

    render template: 'message_drafts/update_body' unless @message.valid?(:validate_data)
  end

  def destroy
    authorize @message_object

    @message_object.destroy

    render partial: 'list'
  end

  private

  def set_message_object
    @message_object = policy_scope(MessageObject).find(params[:id])
  end

  def set_message
    @message = Message.find(params[:message_id])
  end

  def message_object_params
    params.permit(:name, :mimetype, :content, :signed_by)
  end

  def mark_message_object_as_signed(message_object)
    permitted_params = message_object_params

    signed_by_metadata = permitted_params[:signed_by].split(',').map {|part| part.strip.split('=')}.to_h
    signed_by_name = signed_by_metadata['CN']

    message_object.transaction do
      message_object.update!(
        name: permitted_params[:name],
        mimetype: permitted_params[:mimetype],
        is_signed: true,
        signed_by_metadata: permitted_params[:signed_by]
      )

      message_object.message_object_datum.update!(
        blob: Base64.decode64(permitted_params[:content])
      )

      signed_by = User.find_by(name: signed_by_name) || Current.user
      message_object.mark_signed_by_user(signed_by)
    end
  end
end
