class MessageObjectsController < ApplicationController
  before_action :set_message_object, except: :create
  before_action :set_message, only: [:create, :destroy]

  def create
    authorize @message

    MessageObject.create_message_objects(@message, params[:attachments])

    redirect_to polymorphic_url(@message)
  end

  def update
    authorize @message_object
    update_message_object(@message_object)
  end

  def show
    authorize @message_object
    send_data @message_object.content, filename: @message_object.name, type: @message_object.mimetype, disposition: :inline
  end

  def download
    authorize @message_object
    send_data @message_object.content, filename: @message_object.name, type: @message_object.mimetype, disposition: :download
  end

  def signing_data
    authorize @message_object

    @message_object_content = @message_object.content

    if @message_object.mimetype == "application/x-eform-xml"
      upvs_form_template = Upvs::FormTemplate.find_by(identifier: @message_object.message.metadata["posp_id"], version: @message_object.message.metadata["posp_version"])

      @message_object_schema = upvs_form_template&.xsd_schema
      @message_object_transformation = upvs_form_template&.xslt_html
      @message_object_content = Upvs::XmlDataContainerBuilder.build_xml(@message_object.message)
    end
  end

  def destroy
    authorize @message_object

    @message_object.destroy

    redirect_to polymorphic_url(@message)
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
