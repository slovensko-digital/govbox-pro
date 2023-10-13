class MessageThreadNotesController < ApplicationController
  before_action :set_message_thread, only: %i[update create]
  before_action :set_message_thread_note, only: %i[update]

  def update
    authorize @message_thread_note
    @message_thread_note.last_updated_at = Time.current
    if @message_thread_note.update(message_thread_note_params)
      redirect_back_or_to message_threads_path(@message_thread), notice: 'Note was successfully updated'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @message_thread_note = @message_thread.build_message_thread_note(message_thread_note_params)
    @message_thread_note.last_updated_at = Time.current
    authorize @message_thread_note

    if @message_thread_note.save
      redirect_back_or_to message_threads_path(@message_thread), notice: 'Note was successfully created'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_message_thread
    @message_thread = policy_scope(MessageThread).find(params[:message_thread_id])
  end

  def set_message_thread_note
    @message_thread_note = policy_scope(MessageThreadNote).find(params[:id])
  end

  def message_thread_note_params
    params.require(:message_thread_note).permit(:note, :last_updated_at)
  end
end
