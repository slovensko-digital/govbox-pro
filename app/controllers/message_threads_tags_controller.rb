class MessageThreadsTagsController < ApplicationController
  before_action :set_message_threads_tag, only: %i[ destroy ]

  def create
    @message_threads_tag = MessageThreadsTag.new(message_threads_tag_params)
    authorize @message_threads_tag

    if @message_threads_tag.save
      redirect_back fallback_location: "/", notice: "Tag was successfully added"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @message_threads_tag
    @message_threads_tag.destroy
    redirect_back fallback_location:"/", notice: "Tag was successfully removed"
  end

  private

  def set_message_threads_tag
    @message_threads_tag = policy_scope(MessageThreadsTag).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def message_threads_tag_params
    params.require(:message_threads_tag).permit(:message_thread_id, :tag_id)
  end
end
