module TagsAssignment
  class FutureChangesComponent < ViewComponent::Base
    def initialize(diff:)
      @diff = diff
    end

    def format_tags(tags)
      helpers.raw(
        tags.map(&:name)
            .map { |name| helpers.content_tag(:strong, "\"#{name}\"") }
            .join(", ")
      )
    end
  end
end
