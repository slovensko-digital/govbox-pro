class MessageThreadNoteComponent < ViewComponent::Base
  def initialize(message_thread_note)
    @message_thread_note = message_thread_note
    @message_thread = @message_thread_note.message_thread
  end
end
