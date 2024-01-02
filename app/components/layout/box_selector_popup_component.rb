class Layout::BoxSelectorPopupComponent < ViewComponent::Base
  SHOW_SEARCH_BOX_COUNT_THRESHOLD = 5

  def initialize(boxes_with_unread_message_counts)
    @boxes_with_unread_message_counts = boxes_with_unread_message_counts
    @all_unread_messages_count = boxes_with_unread_message_counts.values.sum
    @next_sync_at = GoodJob::CronEntry.find("sync_boxes").next_at
  end
end
