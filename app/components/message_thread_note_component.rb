class MessageThreadNoteComponent < ViewComponent::Base
  def initialize(message_thread_note)
    @message_thread_note = message_thread_note
    @message_thread = @message_thread_note.message_thread
  end

  def before_render
    return unless @message_thread_note.updated_at

    @formatted_updated_at = l @message_thread_note.updated_at, format: :long
  end
end
