class MessageThreadsTagsController < ApplicationController
  before_action :set_message_threads_tag

  def destroy
    authorize @message_threads_tag
    @message_threads_tag.destroy
    redirect_back fallback_location: message_threads_path, notice: "Štítok bol úspešne odstránený"
  end

  private

  def set_message_threads_tag
    @message_threads_tag = policy_scope(MessageThreadsTag).find(params[:id])
  end
end
