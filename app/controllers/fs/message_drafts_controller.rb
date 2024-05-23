class Fs::MessageDraftsController < ApplicationController
  def new
    @message = MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end

  def create
    @message = ::Fs::MessageDraft.create_and_validate_with_fs_form(form_files: message_draft_params[:content])

    authorize @message

    unless @message.valid?
      render :update_new and return
    end

    redirect_to message_thread_path(@message.thread)
  end

  private

  def message_draft_params
    params.permit(
      :sender_id,
      :form_id,
      :content
    )
  end
end
