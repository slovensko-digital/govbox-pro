class MessagesController < ApplicationController
  before_action :set_message

  def show
    authorize @message

    @notice = notice
  end

  def reply
    authorize @message

    # TODO create temporary message
  end

  def submit_reply
    authorize @message

    permitted_params = permit_reply_params
    Govbox::SubmitMessageReplyJob.perform_later(@message, permitted_params[:reply_title], permitted_params[:reply_text])
    Govbox::SyncBoxJob.set(wait: 2.minutes).perform_later(@message.thread.folder.box)
  end

  private

  def set_message
    @message = policy_scope(Message).find(params[:id])
  end

  def permit_reply_params
    params.permit(:reply_title, :reply_text)
  end
end
