class MessageDraftsController < ApplicationController
  before_action :set_message, only: :create
  before_action :set_message_draft, only: [:update, :submit, :show]

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
      Govbox::SubmitMessageReplyJob.perform_later(@message_draft)
      redirect_to message_path(@message_draft.original_message), notice: "Správa bola zaradená na odoslanie."
    else
      redirect_to message_draft_path(@message_draft), notice: "Vyplňte predmet a text odpovede."
    end
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:original_message_id])
  end

  def set_message_draft
    @message_draft = MessageDraft.find(params[:id])
  end

  def message_params
    params.permit(:message_title, :message_text)
  end
end
