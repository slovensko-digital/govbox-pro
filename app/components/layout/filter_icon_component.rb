class Layout::FilterIconComponent < ViewComponent::Base
  def initialize(filter:, size: "w-6 h-6")
    @filter = filter
    @size = size
  end

  def icon_classes
    color = @filter.tag&.color || "gray"
    "#{@size} shrink-0 text-#{color}-600"
  end
end
