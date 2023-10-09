class MessageThreadsTagsController < ApplicationController
  before_action :set_message_threads_tag, only: %i[destroy]

  def create
    @message_threads_tag = MessageThreadsTag.new(
      message_threads_tag_params.to_h.merge(tag_creation_params: tag_creation_params)
    )
    authorize @message_threads_tag

    if @message_threads_tag.save
      redirect_back fallback_location: message_threads_path, notice: "Tag was successfully added"
    else
      redirect_back fallback_location: message_threads_path, alert: "Tag was not added :("
    end
  end

  def destroy
    authorize @message_threads_tag
    @message_threads_tag.destroy
    redirect_back fallback_location: message_threads_path, notice: "Tag was successfully removed"
  end

  private

  def set_message_threads_tag
    @message_threads_tag = policy_scope(MessageThreadsTag).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def message_threads_tag_params
    params.require(:message_threads_tag).permit(:message_thread_id, :tag_id, :tag_name)
  end

  def tag_creation_params
    {
      owner: Current.user,
      tenant: Current.tenant,
      groups: [Current.user.user_group]
    }
  end
end
