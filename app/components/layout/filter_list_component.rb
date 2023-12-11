class Layout::FilterListComponent < ViewComponent::Base
  include MessageThreadHelper

  def initialize(label: nil, filters:)
    @label = label
    @filters = filters
  end

  def icon_for(filter)
    case filter
    when TagFilter then Icons::TagComponent.new
    else Icons::BookmarkComponent.new
    end
  end
end
