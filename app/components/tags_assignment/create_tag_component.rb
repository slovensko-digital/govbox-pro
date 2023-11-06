module TagsAssignment
  class CreateTagComponent < ViewComponent::Base
    def initialize(tags_filter:, create_path:)
      @tags_filter = tags_filter
      @create_path = create_path
    end
  end
end
