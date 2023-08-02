class Layout::TagListComponent < ViewComponent::Base
  def initialize(tags:)
    @tags = tags
  end
end
