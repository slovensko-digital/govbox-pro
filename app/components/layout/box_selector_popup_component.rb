class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  SHOW_SEARCH_BOX_COUNT_THRESHOLD = 5

  def initialize(boxes)
    @boxes = boxes
  end
end
