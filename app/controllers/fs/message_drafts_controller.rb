class Fs::MessageDraftsController < ApplicationController
  def new
    @message = Fs::MessageDraft.new
    @boxes = Current.tenant&.boxes.where(type: 'Fs::Box')
    @box = Current.box

    authorize @message
  end

  def create
    authorize ::Fs::MessageDraft

    redirect_back fallback_location: new_fs_message_draft_path, alert: 'Nahrajte súbory' and return unless message_draft_params[:content].present?

    messages, failed_files = ::Fs::MessageDraft.create_and_validate_with_fs_form(form_files: message_draft_params[:content], author: Current.user)

    if failed_files.empty? && messages.none? {|msg| msg.invalid? }
      redirect_path = messages.size == 1 ? message_thread_path(messages.first.thread) : message_threads_path
      redirect_to redirect_path, notice: 'Správy boli úspešne nahraté'
    elsif failed_files.any?
      session[:sticky_note_type] = 'failed_files'
      session[:sticky_note_data] = failed_files.map(&:original_filename)
      redirect_to message_threads_path
    else
      alert_msg = messages.all? {|msg| msg.invalid? } ? 'Nahratie správ nebolo úspešné' : 'Niektoré zo správ sa nepodarilo nahrať'
      redirect_to message_threads_path, alert: alert_msg
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
