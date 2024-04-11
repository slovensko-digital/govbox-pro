class Api::MessagesController < Api::TenantController
  before_action :set_en_locale
  before_action :load_box, only: :message_drafts
  before_action :check_message_type, only: :message_drafts

  ALLOWED_MESSAGE_TYPES = ['Upvs::MessageDraft']

  def show
    @message = @tenant.messages.find(params[:id])
  end

  def message_drafts
    render_unprocessable_entity('Invalid sender') and return unless @box

    ::Message.transaction do
      @message = permitted_params[:type].classify.safe_constantize.load_and_validate(permitted_params, box: @box)
      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?

      permitted_params.fetch(:objects, []).each do |object_params|
        message_object = @message.objects.create(object_params.except(:content, :tags))
        message_object.tags += message_object.is_signed ? [@message.thread.box.tenant.signed_externally_tag!] : []

        object_params.fetch(:tags, []).each do |tag_name|
          tag = find_tenant_tag_by_name(tag_name)
          render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return unless tag

          message_object.add_tag(tag)
        end

        MessageObjectDatum.create(
          message_object: message_object,
          blob: Base64.decode64(object_params[:content])
        )
      end

      permitted_params.fetch(:tags, []).each do |tag_name|
        tag = find_tenant_tag_by_name(tag_name)
        render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return unless tag

        @message.add_cascading_tag(tag)
      end

      if @message.valid?(:validate_data)
        @message.metadata['status'] = 'created'
        @message.save

        head :created
      else
        @message.destroy

        render_unprocessable_entity(@message.errors.messages.values.join(', '))
      end
    end
  end

  private

  def find_tenant_tag_by_name(tag_name)
    tag = @tenant.tags.find_by(name: tag_name)
    @message.destroy unless tag

    tag
  end

  def permitted_params
    params.permit(
      :type,
      :uuid,
      :title,
      metadata: [
        :correlation_id,
        :reference_id,
        :sender_uri,
        :recipient_uri,
        :sender_business_reference,
        :recipient_business_reference,
        :posp_id,
        :posp_version,
        :message_type,
        :sktalk_class
      ],
      objects: [
        :name,
        :is_signed,
        :to_be_signed,
        :mimetype,
        :object_type,
        :content,
        tags: []
      ],
      tags: []
    )
  end

  def check_message_type
    render_bad_request(ActionController::BadRequest.new("Disallowed message type: #{params[:type]}")) unless params[:type].in?(ALLOWED_MESSAGE_TYPES)
  end

  def load_box
    @box = @tenant.boxes.find_by(uri: permitted_params[:metadata][:sender_uri])
  end
end
