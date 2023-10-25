class TagsAssignment
  ADD_SIGN = "+"
  REMOVE_SIGN = "-"

  class Diff
    attr_reader :to_add, :to_remove

    def initialize(to_add: [], to_remove: [])
      @to_add = to_add
      @to_remove = to_remove
    end

    def number_of_changes
      to_add.length + to_remove.length
    end
  end

  def self.init(all_tags, assigned_ids)
    all_tags.map { |tag| [tag.id.to_s, to_checkbox_value(assigned_ids.include?(tag.id))] }.to_h
  end

  def self.add_new_tag(current_assignment, tag)
    current_assignment[tag.id.to_s] = ADD_SIGN
    current_assignment
  end

  def self.make_diff(init_state, new_state, tag_scope)
    to_add = []
    to_remove = []

    new_state.each do |key, value|
      if init_state.key?(key)
        if init_state[key] != value
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

    Diff.new(to_add: ids_to_tags(to_add, tag_scope), to_remove: ids_to_tags(to_remove, tag_scope))
  end

  def self.ids_to_tags(ids, tag_scope)
    if ids.present?
      tag_scope.find(ids)
    else
      []
    end
  end

  def self.to_checkbox_value(value)
    value ? ADD_SIGN : REMOVE_SIGN
  end
end
