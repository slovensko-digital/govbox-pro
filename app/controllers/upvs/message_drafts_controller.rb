class Upvs::MessageDraftsController < ApplicationController
  before_action :ensure_drafts_import_enabled, only: :index
  before_action :load_message_drafts, only: :index
  before_action :load_original_message, only: :create
  before_action :load_box, only: :create
  before_action :load_message_template, only: :create
  before_action :load_message_draft, except: [:new, :index, :create]

  include ActionView::RecordIdentifier
  include MessagesConcern
  include MessageThreadsConcern

  def new
    @templates_list = MessageTemplate.tenant_templates_list(Current.tenant)
    @message_template = MessageTemplate.default_template
    @message = Upvs::MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Upvs::Box')
    @box = Current.box
    @recipients_list = @message_template&.recipients&.pluck(:institution_name, :institution_uri)&.map { |name, uri| { uri: uri, name: name }}

    authorize @message
  end

  def index
    @messages = @messages.order(created_at: :desc)
  end

  def create
    @message = @message_template&.create_message(
      author: Current.user,
      box: @box,
      recipient_name: new_message_draft_params[:recipient_name],
      recipient_uri: new_message_draft_params[:recipient_uri]
    )

    authorize @message

    unless @message.valid?(:create_from_template)
      @templates_list = MessageTemplate.tenant_templates_list(Current.tenant)
      @message_template ||= MessageTemplate.default_template
      @boxes = Current.tenant&.boxes.where(type: 'Upvs::Box')
      @box ||= Current.box if Current.box || @boxes.first

      @recipients_list = @message_template&.recipients&.pluck(:institution_name, :institution_uri)&.map { |name, uri| { uri: uri, name: name }}

      render :update_new and return
    end

    redirect_to message_thread_path(@message.thread)
  end

  def show
    authorize @message

    @message_thread = @message.thread

    set_thread_messages
    set_visible_tags_for_thread
  end

  private

  def ensure_drafts_import_enabled
    redirect_to message_threads_path(q: "label:(#{Current.tenant.draft_tag.name})") unless Current.tenant.feature_enabled?(:message_draft_import)
  end

  def load_message_drafts
    authorize Upvs::MessageDraft
    @messages = policy_scope(Upvs::MessageDraft)
  end

  def load_original_message
    @original_message = policy_scope(Message).find(params[:original_message_id]) if params[:original_message_id]
  end

  def load_box
    @box = Box.find(new_message_draft_params[:sender_id]) if new_message_draft_params[:sender_id].present?
  end

  def load_message_template
    @message_template = policy_scope(MessageTemplate).find(new_message_draft_params[:message_template_id]) if new_message_draft_params[:message_template_id].present?
  end

  def load_message_draft
    @message = policy_scope(Upvs::MessageDraft).find(params[:id])
  end

  def message_draft_params
    attributes = MessageTemplateParser.parse_template_placeholders(@message.template).map{|item| item[:name]}
    params[:message_draft].permit(attributes)
  end

  def new_message_draft_params
    params.permit(:message_template_id, :sender_id, :recipient_name, :recipient_uri)
  end
end
