class TagsChanges
  ADD_SIGN = "+"
  REMOVE_SIGN = "-"
  KEEP_AS_IS_SIGN = "="

  class Helpers
    def self.to_checkbox_value(value)
      value ? ADD_SIGN : REMOVE_SIGN
    end

    def self.ids_to_tags(ids, tag_scope)
      if ids.present?
        tag_scope.find(ids)
      else
        []
      end
    end

    def self.build_assignment(message_thread:, tag_scope:)
      assigned_ids = message_thread.tag_ids
      init_assignments = tag_scope.to_a.map { |tag| [tag.id.to_s, to_checkbox_value(assigned_ids.include?(tag.id))] }.to_h

      {
        init: init_assignments,
        new: init_assignments,
      }
    end

    def self.build_bulk_assignments(message_threads:, tag_scope:)
      tag_ids = tag_scope.pluck(:id)

      init_assignments = tag_ids.map { |tag_id| [tag_id.to_s, REMOVE_SIGN] }.to_h

      assigned_thread_by_tag = MessageThreadsTag.where(message_thread: message_threads).pluck(:tag_id, :message_thread_id).group_by(&:first)
      assigned_thread_by_tag.each do |tag_id, values|
        init_assignments[tag_id.to_s] = values.length == message_threads.length ? ADD_SIGN : KEEP_AS_IS_SIGN
      end

      {
        init: init_assignments,
        new: init_assignments,
      }
    end
  end

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

  class Diff
    attr_reader :to_add, :to_remove

    def initialize(to_add: [], to_remove: [])
      @to_add = to_add
      @to_remove = to_remove
    end

    def number_of_changes
      to_add.length + to_remove.length
    end

    def self.build_from_assignments(assignements, tag_scope)
      to_add = []
      to_remove = []

      assignements[:new].each do |key, value|
        if assignements[:init].key?(key)
          if assignements[:init][key] != value
            if value == ADD_SIGN
              to_add << key
            elsif value == REMOVE_SIGN
              to_remove << key
            end
          end
        else
          if value == ADD_SIGN
            # added to DB while editing, and we care about it only if user what to add it
            to_add << key
          end
        end
      end

      new(to_add: Helpers.ids_to_tags(to_add, tag_scope), to_remove: Helpers.ids_to_tags(to_remove, tag_scope))
    end
  end

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

  def add_new_tag(tag)
    new_assignments[tag.id.to_s] = ADD_SIGN
    build_diff
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
