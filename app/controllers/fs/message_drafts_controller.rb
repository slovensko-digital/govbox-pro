class Fs::MessageDraftsController < ApplicationController
  def new
    @message = MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end

  def create
    authorize ::Fs::MessageDraft

    messages = ::Fs::MessageDraft.create_and_validate_with_fs_form(form_files: message_draft_params[:content])

    if messages.none?(nil)
      redirect_path = messages.size == 1 ? message_thread_path(messages.first.thread) : message_threads_path
      redirect_to redirect_path, notice: 'Správy boli úspešne nahraté'
    elsif messages.all?(nil)
      redirect_to message_threads_path, alert: 'Nahratie správ nebolo úspešné'
    else
      redirect_to message_threads_path, alert: 'Niektoré zo správ sa nepodarilo nahrať'
    end
  end

  private

  def message_draft_params
    params.permit(
      :sender_id,
      :form_id,
      content: []
    )
  end
end