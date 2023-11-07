class MessageThreadOptionsComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
  end

  def before_render
    if @message_thread.message_thread_note&.note.present?
      @note_link = edit_message_thread_message_thread_note_path(@message_thread, @message_thread.message_thread_note)
      @note_text = 'Upraviť poznámku'
    else
      @note_link = new_message_thread_message_thread_note_path(@message_thread)
      @note_text = 'Pridať poznámku'
    end
  end
end
