class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  SHOW_SEARCH_BOX_COUNT_THRESHOLD = 5

  def initialize(boxes)
    @boxes = boxes
    @next_sync_at = GoodJob::CronEntry.find("sync_boxes").next_at
  end
end
