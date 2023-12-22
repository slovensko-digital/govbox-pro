class MessageObjectsController < ApplicationController
  before_action :set_message_object, except: :create
  before_action :set_message, only: [:create, :update, :destroy]

  def create
    authorize @message

    MessageObject.create_message_objects(@message, params[:attachments])

    render partial: "list"
  end

  def update
    authorize @message_object
    mark_message_object_as_signed(@message_object)
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

  def download_archived
    authorize @message_object
    send_data @message_object.archived_object.content, filename: MessageObjectHelper.displayable_name(@message_object), type: @message_object.mimetype, disposition: :download
  end

  def signing_data
    authorize @message_object

    head :no_content and return unless @message_object.content.present?

    if @message_object.mimetype == "application/x-eform-xml"
      # TODO: this should be handled by autogram
      upvs_form_template = Upvs::FormTemplate.find_by(identifier: @message_object.message.metadata["posp_id"], version: @message_object.message.metadata["posp_version"])

      @message_object_identifier = Upvs::FormBuilder.parse_xml_identifier(@message_object.content)
      @message_object_container_xmlns = "http://data.gov.sk/def/container/xmldatacontainer+xml/1.1"
      @message_object_schema = upvs_form_template&.xsd_schema
      @message_object_transformation = upvs_form_template&.xslt_html
    end
  end

  def destroy
    authorize @message_object

    @message_object.destroy

    render partial: "list"
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
