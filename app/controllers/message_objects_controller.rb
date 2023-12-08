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
    update_message_object(@message_object)
    last_thread_message_draft = @message.thread.messages_visible_to_user(Current.user).where(type: 'MessageDraft').includes(objects: :nested_message_objects, attachments: :nested_message_objects).order(delivered_at: :asc)&.last
    @is_last = @message == last_thread_message_draft
  end

  def show
    authorize @message_object
    send_data @message_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :inline
  end

  def download
    authorize @message_object
    send_data @message_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :download
  end

  def signing_data
    authorize @message_object

    head :no_content and return unless @message_object.content.present?
    render template: 'message_drafts/update_body' and return unless @message.valid?(:validate_data)
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
    params.permit(:name, :mimetype, :is_signed, :content)
  end

  def update_message_object(message_object)
    permitted_params = message_object_params

    message_object.transaction do
      message_object.update!(
        name: permitted_params[:name],
        mimetype: permitted_params[:mimetype],
        is_signed: permitted_params[:is_signed],
      )

      message_object.message_object_datum.update!(
        blob: Base64.decode64(permitted_params[:content])
      )
    end
  end
end
