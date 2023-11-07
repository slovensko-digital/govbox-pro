class MessageThreadNoteFormComponent < ViewComponent::Base
  def initialize(message_thread_note)
    @message_thread_note = message_thread_note
    @message_thread = @message_thread_note.message_thread

    # TODO: Spravit poriadny autogrower
    note_lines = @message_thread_note.note&.lines&.count || 0
    @note_area_size = [3, note_lines].max
  end
end
