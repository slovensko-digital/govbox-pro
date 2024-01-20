class MessageDraftsController < ApplicationController
  before_action :ensure_drafts_enabled, only: :index
  before_action :load_message_drafts, only: %i[index submit_all]
  before_action :load_original_message, only: :create
  before_action :load_box, only: :create
  before_action :load_message_template, only: :create
  before_action :load_message_draft, except: [:new, :index, :create, :submit_all]

  include ActionView::RecordIdentifier
  include MessagesConcern
  include MessageThreadsConcern

  def new
    @templates_list = MessageTemplate.tenant_templates_list(Current.tenant)
    @message_template = MessageTemplate.default_template
    @message = MessageDraft.new
    @boxes = Current.tenant.boxes.pluck(:name, :id)
    @box = (Current.box if Current.box || @boxes.first)&.slice(:name, :id).values.to_a
    @recipients_list = @message_template&.recipients&.pluck(:institution_name, :institution_uri)&.map { |name, uri| { uri: uri, name: name }}

    authorize @message
  end

  def index
    @messages = @messages.order(created_at: :desc)
  end

  def create
    @message = MessageDraft.new
    authorize @message

    @user_is_signer = Current.user.signer?

    @message_template&.create_message(
      @message,
      author: Current.user,
      box: @box,
      recipient_name: new_message_draft_params[:recipient_name],
      recipient_uri: new_message_draft_params[:recipient_uri]
    )

    unless @message.valid?(:create_from_template)
      @templates_list = MessageTemplate.tenant_templates_list(Current.tenant)
      @message_template ||= MessageTemplate.default_template
      @boxes = Current.tenant.boxes.pluck(:name, :id)
      @box = @box&.slice(:name, :id).values.to_a

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

  def update
    authorize @message

    @message.update_content(message_draft_params)
  end

  def submit
    authorize @message

    render :update_body and return unless @message.valid?(:validate_data)

    if @message.submittable?
      Govbox::SubmitMessageDraftJob.perform_later(@message)
      @message.being_submitted!
      redirect_to message_thread_path(@message.thread), notice: "Správa bola zaradená na odoslanie"
    else
      # TODO: prisposobit chybovu hlasku aj importovanym draftom
      redirect_to message_thread_path(@message.thread), alert: "Vyplňte text správy"
    end
  end

  def submit_all
    jobs_batch = GoodJob::Batch.new

    @messages.each do |message_draft|
      next unless message_draft.submittable?

      jobs_batch.add { Govbox::SubmitMessageDraftJob.perform_later(message_draft, schedule_sync: false) }
      message_draft.being_submitted!
    end

    boxes_to_sync = Current.tenant.boxes.joins(message_threads: :messages).where(messages: { id: @messages.map(&:id) }).uniq
    jobs_batch.enqueue(on_finish: Govbox::ScheduleDelayedSyncBoxJob, boxes: boxes_to_sync)
  end

  def destroy
    authorize @message

    # TODO uncomment when /message_drafts endpoint has FE
    # redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_drafts_path
    redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_threads_path

    @message.destroy

    redirect_to redirect_path, notice: "Draft bol zahodený"
  end

  def unlock
    authorize @message
    if @message.remove_form_signature
      redirect_to message_thread_path(@message.thread), notice: "Podpisy boli úspešne odstránené, správu je možné upravovať"
    else
      redirect_to message_thread_path(@message.thread), alert: "Nastala neočakávaná chyba, nepodarilo sa odstrániť podpisy"
    end
  end

  def confirm_unlock
    authorize @message
  end

  private

  def ensure_drafts_enabled
    redirect_to message_threads_path(q: "label:(#{Current.tenant.draft_tag.name})") unless Current.tenant.feature_enabled?(:message_draft_import)
  end

  def load_message_drafts
    authorize MessageDraft
    @messages = policy_scope(MessageDraft)
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
    @message = policy_scope(MessageDraft).find(params[:id])
  end

  def message_draft_params
    attributes = MessageTemplateParser.parse_template_placeholders(@message.template).map{|item| item[:name]}
    params[:message_draft].permit(attributes)
  end

  def new_message_draft_params
    params.permit(:message_template_id, :sender_id, :recipient_name, :recipient_uri)
  end
end
