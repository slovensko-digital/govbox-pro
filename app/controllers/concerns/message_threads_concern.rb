module MessageThreadsConcern
  def set_thread_messages
    @thread_messages = @message_thread.
      messages.includes(objects: [:nested_message_objects, :tags, :archived_object]).
      order(delivered_at: :asc)

    @thread_last_message_draft_id = @thread_messages.to_a.filter { |message| message.is_a?(MessageDraft) }.last&.id
  end
end
