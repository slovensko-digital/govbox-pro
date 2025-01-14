class Api::MessagesController < Api::TenantController
  before_action :set_en_locale
  before_action :load_box, only: :message_drafts
  before_action :check_message_type, only: :message_drafts
  before_action :check_tags, only: :message_drafts

  ALLOWED_MESSAGE_TYPES = ['Upvs::MessageDraft']

  def show
    @message = @tenant.messages.find(params[:id])
  end

  def search
    @message = @tenant.messages.find_by(permitted_search_params)
  end

  def message_drafts
    ::Message.transaction do
      @message = permitted_message_draft_params[:type].classify.safe_constantize.load_from_params(permitted_message_draft_params, box: @box)

      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?
      render_conflict(@message.errors.messages.values.join(', ')) and return unless @message.valid?(:validate_uuid_uniqueness)

      @message.save

      permitted_message_draft_params.fetch(:objects, []).each do |object_params|
        message_object = @message.objects.create(object_params.except(:content, :to_be_signed, :tags))

        object_params.fetch(:tags, []).each do |tag_name|
          tag = @tenant.user_signature_tags.find_by(name: tag_name)
          tag.assign_to_message_object(message_object)
          tag.assign_to_thread(@message.thread)
        end
        @message.thread.box.tenant.signed_externally_tag!.assign_to_message_object(message_object) if message_object.is_signed

        if object_params[:to_be_signed]
          @message.tenant.signer_group.signature_requested_from_tag&.assign_to_message_object(message_object)
          @message.tenant.signer_group.signature_requested_from_tag&.assign_to_thread(@message.thread)
        end

        MessageObjectDatum.create(
          message_object: message_object,
          blob: Base64.decode64(object_params[:content])
        )
      end

      permitted_message_draft_params.fetch(:tags, []).each do |tag_name|
        tag = @tenant.tags.find_by(name: tag_name)
        @message.add_cascading_tag(tag)
      end

      if @message.valid?(:validate_data)
        @message.created!
        head :created
      else
        @message.destroy
        render_unprocessable_entity(@message.errors.messages.values.join(', '))
      end
    end
  end

  def sync
    @messages = @tenant.messages.order(:id).limit(API_PAGE_SIZE).includes(:objects)
    @messages = @messages.where('messages.id > ?', params[:last_id]) if params[:last_id]
  end

  private

  def permitted_search_params
    params.permit(:uuid)
  end

  def permitted_message_draft_params
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
        :description,
        :is_signed,
        :to_be_signed,
        :mimetype,
        :object_type,
        :content,
        { tags: [] }
      ],
      tags: []
    )
  end

  def check_message_type
    render_bad_request(ActionController::BadRequest.new("Disallowed message type: #{params[:type]}")) unless params[:type].in?(ALLOWED_MESSAGE_TYPES)
  end

  def check_tags
    tag_names = permitted_message_draft_params.fetch(:tags, [])
    tag_names.each do |tag_name|
      @tenant.tags.find_by!(name: tag_name)
    rescue ActiveRecord::RecordNotFound
      render_unprocessable_entity("Tag with name #{tag_name} does not exist") and return
    end

    message_object_tag_names = permitted_message_draft_params.fetch(:objects, []).pluck('tags').compact.flatten
    message_object_tag_names.each do |tag_name|
      @tenant.user_signature_tags.find_by!(name: tag_name)
    rescue ActiveRecord::RecordNotFound
      render_unprocessable_entity("Signature tag with name #{tag_name} does not exist") and return
    end
  end

  def load_box
    @box = @tenant.boxes.find_by(uri: permitted_message_draft_params[:metadata][:sender_uri])
    render_unprocessable_entity('Invalid sender') and return unless @box
  end
end
