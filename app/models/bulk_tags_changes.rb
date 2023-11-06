class BulkTagsChanges
  ADD_SIGN = "+"
  KEEP_AS_IS_SIGN = "="
  REMOVE_SIGN = "-"

  class Checkbox
    def initialize(tag_assignments:, tag_id:)
      @tag_assignments = tag_assignments
      @tag_id = tag_id
    end

    def indeterminate?
      init_assignment_value == KEEP_AS_IS_SIGN
    end

    def checked?
      if indeterminate?
        new_assignment_value != REMOVE_SIGN
      else
        new_assignment_value == ADD_SIGN
      end
    end

    def value
      if indeterminate?
        if new_assignment_value == KEEP_AS_IS_SIGN || new_assignment_value == REMOVE_SIGN
          KEEP_AS_IS_SIGN
        else
          ADD_SIGN
        end
      else
        ADD_SIGN
      end
    end

    def init_assignment_value
      @tag_assignments[:init][@tag_id]
    end

    def new_assignment_value
      @tag_assignments[:new][@tag_id]
    end
  end

  attr_reader :diff, :tags_assignments

  def initialize(message_threads:, tag_scope:, tags_assignments: { init: {}, new: {} })
    @message_threads = message_threads
    @tag_scope = tag_scope
    @tags_assignments = tags_assignments.to_h
  end

  def init_assignments
    @tags_assignments[:init]
  end

  def new_assignments
    @tags_assignments[:new]
  end

  def add_new_tag(tag)
    new_assignments[tag.id.to_s] = ADD_SIGN
  end

  def number_of_changes
    @diff.number_of_changes
  end

  def self.build_with_new_assignments(message_threads:, tag_scope:)
    new(
      message_threads: message_threads,
      tag_scope: tag_scope,
    ).tap do |instance|
      instance.build_new_assignments
      instance.build_diff
    end
  end

  def self.build_from_assignments(message_threads:, tag_scope:, tags_assignments:)
    new(
      message_threads: message_threads,
      tag_scope: tag_scope,
      tags_assignments: tags_assignments
    ).tap(&:build_diff)
  end

  def build_new_assignments
    tag_ids = @tag_scope.pluck(:id)

    init_assignments = tag_ids.map { |tag_id| [tag_id.to_s, REMOVE_SIGN] }.to_h

    assigned_thread_by_tag = MessageThreadsTag.where(message_thread: @message_threads).pluck(:tag_id, :message_thread_id).group_by(&:first)
    assigned_thread_by_tag.each do |tag_id, values|
      init_assignments[tag_id.to_s] = values.length == @message_threads.length ? ADD_SIGN : KEEP_AS_IS_SIGN
    end

    @tags_assignments = {
      init: init_assignments,
      new: init_assignments,
    }
  end

  def build_diff
    @diff = TagsChanges::Diff.build_from_assignments(@tags_assignments, @tag_scope)
  end

  def save
    build_diff

    threads = @message_threads.to_a # to avoid subquery error
    create_attributes = threads.product(@diff.to_add).map { |thread, tag| { message_thread: thread, tag: tag } }

    MessageThreadsTag.transaction do
      MessageThreadsTag.create(create_attributes)
      MessageThreadsTag.where(message_thread: threads, tag: @diff.to_remove).destroy_all
    end
  end
end
