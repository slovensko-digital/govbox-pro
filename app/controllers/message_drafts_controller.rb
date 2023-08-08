class MessageDraftsController < ApplicationController
  before_action :load_message_drafts, only: :index
  before_action :set_message, only: :create
  before_action :set_message_draft, except: [:index, :create]

  def index
  end

  def create
    authorize @message

    @message_draft = MessageDraft.create_from_message(@message)

    redirect_to message_draft_path(@message_draft)
  end

  def show
    authorize @message_draft
    @notice = notice
  end

  def update
    authorize @message_draft

    permitted_params = message_params

    @message_draft.title = permitted_params["message_title"]
    @message_draft.metadata["message_body"] = permitted_params["message_text"]
    @message_draft.save!
  end

  def submit
    authorize @message_draft

    if @message_draft.submittable?
      Govbox::SubmitMessageDraftJob.perform_later(@message_draft)

      @message_draft.metadata["status"] = "being_submitted"
      @message_draft.save!

      redirect_to message_path(@message_draft.original_message), notice: "Správa bola zaradená na odoslanie."
    else
      redirect_to message_draft_path(@message_draft), notice: "Vyplňte predmet a text odpovede."
    end
  end

  def destroy
    authorize @message_draft

    @message_draft.destroy
    redirect_to message_path(@message_draft.original_message)
  end

  private

  def load_message_drafts
    authorize MessageDraft
    @message_drafts = policy_scope(MessageDraft)
  end

  def set_message
    @message = policy_scope(Message).find(params[:original_message_id])
  end

  def set_message_draft
    @message_draft = policy_scope(MessageDraft).find(params[:id])
    @menu = SidebarMenu.new(controller_name, action_name, { message: @message_draft })
  end

  def message_params
    params.permit(:message_title, :message_text)
  end
end
