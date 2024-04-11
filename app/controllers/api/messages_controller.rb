class Api::MessagesController < Api::TenantController
  before_action :set_en_locale
  before_action :load_box, only: :message_drafts
  before_action :check_message_type, only: :message_drafts
  before_action :check_tags, only: :message_drafts

  ALLOWED_MESSAGE_TYPES = ['Upvs::MessageDraft']

  def show
    @message = @tenant.messages.find(params[:id])
  end

  def message_drafts
    ::Message.transaction do
      @message = permitted_params[:type].classify.safe_constantize.load_and_validate(permitted_params, box: @box)
      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?

      permitted_params.fetch(:objects, []).each do |object_params|
        message_object = @message.objects.create(object_params.except(:content, :tags))
        message_object.tags += message_object.is_signed ? [@message.thread.box.tenant.signed_externally_tag!] : []

        object_params.fetch(:tags, []).each do |tag_name|
          tag = @tenant.tags.find_by(name: tag_name)
          tag.assign_to_message_object(message_object)
          tag.assign_to_thread(@message.thread)
        end

        MessageObjectDatum.create(
          message_object: message_object,
          blob: Base64.decode64(object_params[:content])
        )
      end

      permitted_params.fetch(:tags, []).each do |tag_name|
        tag = @tenant.tags.find_by(name: tag_name)
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
        tags: []
      ],
      tags: []
    )
  end

  def check_message_type
    render_bad_request(ActionController::BadRequest.new("Disallowed message type: #{params[:type]}")) unless params[:type].in?(ALLOWED_MESSAGE_TYPES)
  end

  def check_tags
    tag_names = permitted_params.fetch(:tags, []) + permitted_params.fetch(:objects, []).map {|o| o['tags'] }.compact

    tag_names.each do |tag_name|
      @tenant.tags.find_by!(name: tag_name)
    rescue ActiveRecord::RecordNotFound
      render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return
    end
  end

  def load_box
    @box = @tenant.boxes.find_by(uri: permitted_params[:metadata][:sender_uri])
    render_unprocessable_entity('Invalid sender') and return unless @box
  end
end
