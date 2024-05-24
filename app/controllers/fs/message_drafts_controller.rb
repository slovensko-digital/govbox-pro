class Fs::MessageDraftsController < ApplicationController
  def new
    @message = MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end

  def create
    authorize ::Fs::MessageDraft

    results = ::Fs::MessageDraft.create_and_validate_with_fs_form(form_files: message_draft_params[:content])

    if results.all?(true)
      redirect_to message_threads_path, notice: 'Správy boli úspešne nahraté'
    elsif results.all?(false)
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
