class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @notice = notice
  end

  def reply
    authorize @message

    # TODO create temporary message

    @notice = notice
  end

  def submit_reply
    authorize @message

    permitted_params = permit_reply_params

    if permitted_params[:reply_title].present? && permitted_params[:reply_text].present?
      Govbox::SubmitMessageReplyJob.perform_later(@message, permitted_params[:reply_title], permitted_params[:reply_text])
      Govbox::SyncBoxJob.set(wait: 2.minutes).perform_later(@message.thread.folder.box)

      redirect_to message_path(@message), notice: "Správa bola odoslaná."
    else
      redirect_to reply_message_path(@message), notice: "Vyplňte predmet a text odpovede."
    end
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
