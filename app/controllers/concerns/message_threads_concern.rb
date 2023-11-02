module MessageThreadsConcern
  def set_visible_tags_for_thread
    @thread_tags =
      @message_thread.message_threads_tags.
        includes(:tag).
        joins(:tag).
        where("tags.visible = ?", true).
        order("tags.name")
  end
end
