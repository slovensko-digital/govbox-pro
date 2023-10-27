class TagsChanges
  ADD_SIGN = "+"
  REMOVE_SIGN = "-"

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

  attr_reader :diff

  def initialize(message_thread:, tag_scope:, tags_assignments: { init: {}, new: {} })
    @message_thread = message_thread
    @tag_scope = tag_scope
    @tags_assignments = tags_assignments
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

  def self.init(message_thread:, tag_scope:)
    new(
      message_thread: message_thread,
      tag_scope: tag_scope,
    ).tap do |instance|
      instance.build_new_assignments
      instance.build_diff
    end
  end

  def self.prepare(message_thread:, tag_scope:, tags_assignments:)
    new(
      message_thread: message_thread,
      tag_scope: tag_scope,
      tags_assignments: tags_assignments
    ).tap(&:build_diff)
  end

  def build_new_assignments
    assigned_ids = @message_thread.tag_ids
    init_assignments = @tag_scope.to_a.map { |tag| [tag.id.to_s, Helpers.to_checkbox_value(assigned_ids.include?(tag.id))] }.to_h

    @tags_assignments = {
      init: init_assignments,
      new: init_assignments,
    }
  end

  def build_diff
    @diff = Diff.build_from_assignments(@tags_assignments, @tag_scope)
  end

  def save
    build_diff
    create_attributes = @diff.to_add.map { |tag| { message_thread: @message_thread, tag: tag } }

    MessageThreadsTag.transaction do
      MessageThreadsTag.create(create_attributes)
      MessageThreadsTag.where(message_thread: @message_thread, tag: @diff.to_remove).destroy_all
    end
  end

end
