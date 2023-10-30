module MessagesConcern
  def set_thread_visible_tags
    @thread_tags =
      @message.
        thread.
        message_threads_tags.
        includes(:tag).
        joins(:tag).
        where("tags.visible = ?", true).
        order("tags.name")
  end
end
