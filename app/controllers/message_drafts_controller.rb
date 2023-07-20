class MessageDraftsController < ApplicationController
  before_action :set_message, only: :create
  before_action :set_message_draft, only: [:submit, :show]

  def create
    authorize @message

    @message_draft = MessageDraft.create_from_message(@message)

    redirect_to message_draft_path(@message_draft)
  end

  def show
    authorize @message_draft
    @notice = notice
  end

  def submit
    authorize @message_draft

    if @message_draft.save
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
end
