class Layout::FilterListComponent < ViewComponent::Base
  include MessageThreadHelper

  def initialize(label: nil, filters:, sortable: false)
    @label = label
    @filters = filters
    @sortable = sortable
  end

  def icon_for(filter)
    return Common::IconComponent.new(filter.icon) if filter.icon.present?

    if filter.tag.present?
      return Common::IconComponent.new(filter.tag.icon) if filter.tag.icon.present?
      return Icons::TagComponent.new
    end

    Icons::BookmarkComponent.new
  end
end
