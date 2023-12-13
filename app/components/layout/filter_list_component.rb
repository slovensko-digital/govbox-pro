class Layout::FilterListComponent < ViewComponent::Base
  include MessageThreadHelper

  def initialize(label: nil, filters:, sortable: false)
    @label = label
    @filters = filters
    @sortable = sortable
  end

  def icon_for(filter)
    case filter
    when TagFilter then Icons::TagComponent.new
    else Icons::BookmarkComponent.new
    end
  end
end
