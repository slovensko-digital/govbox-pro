class Api::MessagesController < Api::TenantController
  before_action :load_box, only: :message_drafts
  before_action :check_message_type, only: :message_drafts
  before_action :check_tags, only: :message_drafts

  ALLOWED_MESSAGE_TYPES = %w[Upvs::MessageDraft Fs::MessageDraft]

  def show
    @message = @tenant.messages.find(params[:id])
  end

  def destroy
    @message = @tenant.messages.find(params[:id])

    if @message.destroyable? && @message.not_yet_submitted?
      @message.destroy
    else
      render_unprocessable_entity("Message is not destroyable")
    end
  end

  def search
    @message = @tenant.messages.find_by(permitted_search_params)

    render_not_found unless @message
  end

  def message_drafts
    ::Message.transaction do
      @message = permitted_message_draft_params[:type].classify.safe_constantize.load_from_params(permitted_message_draft_params, tenant: @tenant, box: @box)

      render_unprocessable_entity(@message.errors.messages.values.join(', ')) and return unless @message.valid?
      render_conflict(@message.errors.messages.values.join(', ')) and return unless @message.valid?(:validate_uuid_uniqueness)

      @message.save

      @message.create_message_objects_from_params(permitted_message_draft_params.fetch(:objects, []))
      @message.assign_tags_from_params(permitted_message_draft_params.fetch(:tags, []))

      if @message.valid?(:validate_data)
        @message.created!
        render json: { id:@message.id, thread_id: @message.message_thread_id }.to_json, status: :created
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
        :business_id,
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
        :identifier,
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
    @box = @tenant.boxes.find_by(uri: permitted_message_draft_params[:metadata]&.dig('sender_uri'))
  end

  rescue_from MessageDraft::InvalidSenderError do
    render_unprocessable_entity('Invalid sender')
  end

  rescue_from MessageDraft::MissingFormObjectError do
    render_unprocessable_entity('Message has to contain exactly one form object')
  end

  rescue_from MessageDraft::UnknownFormError do
    render_unprocessable_entity('Unknown form')
  end
end
