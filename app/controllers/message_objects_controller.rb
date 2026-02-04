class MessageObjectsController < ApplicationController
  before_action :set_message_object, except: :create
  before_action :set_message, only: [:create, :update, :destroy, :signing_data]

  def show
    authorize @message_object
    send_data @message_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :inline
  end

  def create
    authorize @message

    MessageObject.create_message_objects(@message, params[:attachments])

    redirect_to @message.thread
  end

  def update
    authorize @message_object

    mark_message_object_as_signed(@message_object)

    last_thread_message_draft = @message.thread.message_drafts.includes(objects: :nested_message_objects, attachments: :nested_message_objects).order(delivered_at: :asc)&.last
    @is_last = @message == last_thread_message_draft
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
      redirect_back_or_to(message_thread_path(@message_object.message.thread), alert: "Obsah nie je možné stiahnuť.")
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

    return if @message.valid?(:validate_data)

    respond_to do |format|
      format.turbo_stream do
        render template: 'message_drafts/update_body'
      end

      format.json do
        render json: { errors: @message.errors.full_messages }, status: :unprocessable_content
      end
    end
  end

  def destroy
    authorize @message_object

    @message_object.destroy
    EventBus.publish(:message_attachments_changed_by_user, @message_object.message)

    redirect_to @message.thread
  end

  private

  def set_message_object
    @message_object = policy_scope(MessageObject).find(params[:id])
  end

  def set_message
    @message = Message.find(params[:message_id])
  end

  def message_object_params
    params.permit(:name, :mimetype, :content)
  end

  def mark_message_object_as_signed(message_object)
    permitted_params = message_object_params

    message_object.transaction do
      message_object.update!(
        name: permitted_params[:name],
        mimetype: permitted_params[:mimetype],
        is_signed: true
      )

      message_object.message_object_datum.update!(
        blob: Base64.decode64(permitted_params[:content])
      )

      message_object.mark_signed_by_user(Current.user)
    end
  end
end
