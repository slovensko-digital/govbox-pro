class SignersChanges
  ADD_SIGN = "+"
  REMOVE_SIGN = "-"
  KEEP_SIGN = "="


  attr_reader :diff, :tags_assignments

  def initialize(tag_scope:, tags_assignments: { init: {}, new: {} })
    @tag_scope = tag_scope
    @tags_assignments = tags_assignments.to_h
    build_diff
  end

  def init_assignments
    @tags_assignments[:init]
  end

  def new_assignments
    @tags_assignments[:new]
  end

  def number_of_changes
    @diff.number_of_changes
  end

  def build_diff
    @diff = Diff.build_from_assignments(@tags_assignments, @tag_scope)
  end

  def save(message_thread)
    bulk_save([message_thread])
  end

  def bulk_save(message_threads)
    threads = message_threads.to_a # to avoid subquery error
    create_attributes = threads.product(@diff.to_add).map { |thread, tag| { message_thread: thread, tag: tag } }

    MessageThreadsTag.transaction do
      MessageThreadsTag.create(create_attributes)
      MessageThreadsTag.where(message_thread: threads, tag: @diff.to_remove).destroy_all
    end
  end
end
