module MessagesConcern
  def set_visible_tags_for_thread
    @thread_tags = @message.thread.message_threads_tags.only_visible_tags
  end
end
