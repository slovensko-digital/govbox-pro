class MessagesTagsController < ApplicationController
  before_action :set_messages_tag, only: %i[destroy]

  def create
    @messages_tag = MessagesTag.new(messages_tag_params)
    authorize @messages_tag

    if @messages_tag.save
      redirect_back fallback_location: "/", notice: "Štítok bol úspešne vytvorený"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @messages_tag
    @messages_tag.destroy
    redirect_back fallback_location: '/', notice: 'Štítok bol úspešne odstránený'
  end

  private

  def set_messages_tag
    @messages_tag = policy_scope(MessagesTag).find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def messages_tag_params
    params.require(:messages_tag).permit(:message_id, :tag_id)
  end
end
