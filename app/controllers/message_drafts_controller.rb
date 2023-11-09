class MessageDraftsController < ApplicationController
  before_action :load_message_drafts, only: %i[index submit_all]
  before_action :load_original_message, only: :create
  before_action :load_message_draft, except: [:index, :create, :submit_all]

  include ActionView::RecordIdentifier
  include MessagesConcern

  def index
    @messages = @messages.order(created_at: :desc)
  end

  def create
    authorize @original_message

    @message = MessageDraft.create_message_reply(original_message: @original_message, author: Current.user)
  end

  def show
    authorize @message

    @message_thread = @message.thread
    @thread_messages = @message_thread.messages_visible_to_user(Current.user).order(delivered_at: :asc)
    @thread_last_message_draft_id = @message_thread.messages_visible_to_user(Current.user).where(type: 'MessageDraft').includes(objects: :nested_message_objects, attachments: :nested_message_objects).order(delivered_at: :asc)&.last&.id
    set_visible_tags_for_thread
  end

  def update
    authorize @message

    permitted_params = message_params

    @message.update_content(title: permitted_params["message_title"], body: permitted_params["message_text"])
  end

  def submit
    authorize @message

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

    jobs_batch.enqueue(on_finish: Govbox::FinishMessageDraftsSubmitJob, box: @messages.first.thread.folder.box)
  end

  def destroy
    authorize @message

    redirect_path = @message.original_message.present? ? message_thread_path(@message.original_message.thread) : message_drafts_path

    @message.destroy

    redirect_to redirect_path, notice: "Draft bol zahodený"
  end

  private

  def load_message_drafts
    authorize MessageDraft
    @messages = policy_scope(MessageDraft)
  end

  def load_original_message
    @original_message = policy_scope(Message).find(params[:original_message_id])
  end

  def load_message_draft
    @message = policy_scope(MessageDraft).find(params[:id])
  end

  def message_params
    params.permit(:message_title, :message_text)
  end
end
