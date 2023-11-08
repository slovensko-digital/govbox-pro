class MessageThreadNotesController < ApplicationController
  before_action :set_message_thread, only: %i[update create new edit]
  before_action :set_message_thread_note, only: %i[update edit]

  def update
    authorize @message_thread_note
    if @message_thread_note.update(message_thread_note_params)
      redirect_back_or_to message_threads_path(@message_thread)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def new
    authorize MessageThreadNote
    @message_thread_note = @message_thread.build_message_thread_note
  end

  def edit
    authorize @message_thread_note
  end

  def create
    @message_thread_note = @message_thread.build_message_thread_note(message_thread_note_params)
    authorize @message_thread_note

    if @message_thread_note.save
      redirect_back_or_to message_threads_path(@message_thread)
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
