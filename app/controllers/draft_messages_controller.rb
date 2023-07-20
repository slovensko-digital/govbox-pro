class DraftMessagesController < ApplicationController
  before_action :set_message, only: :create
  before_action :set_draft_message, only: [:submit, :show]

  def create
    authorize @message

    @draft_message = DraftMessage.create_from_message(@message)

    redirect_to draft_message_path(@draft_message)
  end

  def show
    authorize @draft_message
    @notice = notice
  end

  def submit
    authorize @draft_message

    if @draft_message.save
      redirect_to message_path(@draft_message.original_message), notice: "Správa bola zaradená na odoslanie."
    else
      redirect_to draft_message_path(@draft_message), notice: "Vyplňte predmet a text odpovede."
    end
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:original_message_id])
  end

  def set_draft_message
    @draft_message = DraftMessage.find(params[:id])
  end
end
