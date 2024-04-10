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
      @message = ::Message.create(permitted_params.except(:objects, :tags).merge({
        sender_name: @box.name,
        # recipient_name: TODO search name in UPVS dataset,
        outbox: true,
        replyable: false,
        delivered_at: Time.now
      }))
      @message.thread = @box&.message_threads&.find_or_build_by_merge_uuid(
        box: @box,
        merge_uuid: @message.metadata['correlation_id'],
        title: @message.title,
        delivered_at: @message.delivered_at
      )

      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?
      @message.save

      permitted_params.fetch(:objects, []).each do |object_params|
        message_object = @message.objects.create(object_params.except(:content))
        object_tags = message_object.is_signed ? [@message.thread.box.tenant.signed_externally_tag!] : []

        message_object.tags += object_tags

        MessageObjectDatum.create(
          message_object: message_object,
          blob: Base64.decode64(object_params[:content])
        )
      end

      permitted_params.fetch(:tags, []).each do |tag_name|
        tag = @tenant.tags.find_by(name: tag_name)

        unless tag
          @message.destroy
          render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return
        end

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
